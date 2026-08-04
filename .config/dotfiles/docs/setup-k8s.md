# ローカル Kubernetes

GKE とオンプレの両方に移せることを狙って、k3s を upstream 寄りに構成している。

設定は `nix/modules/k3s.nix`。常駐するサービスなので、使うホストだけが import する。

## 方針

k3s は既定のままだと upstream との差が大きい。移行時に効いてくる差から順に潰してある。

| 項目 | k3s 既定 | この構成 | 理由 |
| --- | --- | --- | --- |
| datastore | kine (SQLite) | **embedded etcd** | 差が一番大きいところ。`clusterInit` で切り替わる |
| CNI | flannel | **Cilium** | GKE の Dataplane V2 が Cilium ベース |
| kube-proxy | あり | **なし** (Cilium が置換) | Dataplane V2 も kube-proxy なし |
| NetworkPolicy | k3s 内蔵 | **Cilium** | 挙動を本番と揃える |
| Ingress | traefik | **ingress-nginx** | GKE でもオンプレでも同じものが使える |
| LoadBalancer | servicelb | (未導入) | 本番のものに合わせる。下記「残っている差」を参照 |
| StorageClass | local-path | (未導入) | 本番の CSI に合わせる |
| バージョン | nixpkgs 任せ | **固定** | 更新で勝手にマイナーが上がらないようにする |

k3s のバージョンは `nix/modules/k3s.nix` の `package` で固定している。本番のマイナーバージョンが決まったら、そこを `pkgs.k3s_1_XX` に合わせる。

## 残っている差

これらは把握したうえで残してある。

- **コンポーネントが単一プロセス** — kube-apiserver / controller-manager / scheduler が 1 バイナリに同居している。個別コンポーネントの障害を再現する検証には向かない
- **LoadBalancer** — 本番 (GKE) はクラウド LB になる。ローカルで再現するには Cilium の LB IPAM と L2 広告が要るが、WSL の仮想ネットワークには広告先がない。当面 Ingress は NodePort で通す
- **StorageClass** — 本番の CSI ドライバに合わせて別途入れる
- **kubelet の一部デフォルト値** が k3s 独自。必要なら `services.k3s.extraKubeletConfig` で寄せられる

## 使う

kubeconfig は `KUBECONFIG` 環境変数で設定済みなので、そのまま使える。

```sh
kubectl get nodes
kubectl get pods -A
k9s
```

起動直後は Cilium が入るまで Pod が `Pending` のままになる。CNI が無い状態では正常な挙動なので、少し待つ。

```sh
kubectl -n kube-system get pods -l k8s-app=cilium
cilium status
```

## イメージを作る

k3s の containerd をそのまま使うので、**レジストリへの push も import も要らない**。ビルドは Dockerfile をそのまま書けばよい。

```sh
nerdctl build -t myapp:dev .

kubectl run myapp --image=myapp:dev --image-pull-policy=Never
```

`nerdctl` は `sudo -E nerdctl` の alias にしてある。k3s の containerd ソケットが root 所有で、一般ユーザーのまま起動すると nerdctl が rootless モードに入って別のソケットを探しにいくため。`-E` は `CONTAINERD_ADDRESS` と `CONTAINERD_NAMESPACE` を sudo 越しに引き継ぐためのもの。

スクリプトから呼ぶときは shell alias が効かないので、`sudo -E nerdctl` と直接書く。

`imagePullPolicy: Never` が要るのは、タグ付きイメージを見つけると kubelet が既定でレジストリを引きに行くため。

Deployment に書く場合:

```yaml
spec:
  template:
    spec:
      containers:
        - name: myapp
          image: myapp:dev
          imagePullPolicy: Never
```

## 設定を変える

`nix/modules/k3s.nix` を編集して反映する。

```sh
sudo nixos-rebuild switch --flake ~/.config/dotfiles#wsl
```

### Helm chart を足す / 上げる

`services.k3s.autoDeployCharts` に書く。k3s の helm-controller が拾って適用するので、クラスタを作り直しても同じ状態が再現する。

chart の hash は取得して埋める:

```sh
nix store prefetch-file --json https://helm.cilium.io/cilium-1.20.0.tgz | jq -r .hash
```

`repo` には **helm リポジトリの URL** (`index.yaml` が置いてある場所) を書く。tarball の URL を直接書いても通らない。取得は helm 自身が行い、`index.yaml` から実体の場所を解決する。ingress-nginx のように tarball が GitHub Release にあるものでも、指定するのは `https://kubernetes.github.io/ingress-nginx` の側。

**`--disable-helm-controller` を付けてはいけない。** `autoDeployCharts` を処理しているのが helm-controller なので、外すと chart が適用されなくなる。

## クラスタを作り直す

```sh
sudo systemctl stop k3s
sudo k3s-killall.sh
sudo rm -rf /var/lib/rancher/k3s/server/db
sudo systemctl start k3s
```

`autoDeployCharts` の内容は再適用されるので、Cilium と ingress-nginx は自動で戻る。

## トラブルシューティング

### Pod が Pending のまま進まない (untolerated taint)

```
0/1 nodes are available: 1 node(s) had untolerated taint(s)
```

CNI がないと kubelet が Ready にならず、ノードに not-ready の taint が付く。この状態で **Cilium を入れる Job 自身がその taint で弾かれる**と、CNI が永久に入らないデッドロックになる。

`nix/modules/k3s.nix` で Cilium の chart に `spec.bootstrap = true` を立ててあるのはこのため。k3s はこのフラグの付いた chart をクラスタ起動に必要なものとして扱い、taint を無視して先に流す。

反映されているか確認する:

```sh
kubectl -n kube-system get helmchart cilium -o jsonpath='{.spec.bootstrap}'   # true
```

`extraFieldDefinitions` はリソースのトップレベルにマージされるので、`spec` まで含めて書かないと効かない。

### Pod が ContainerCreating のまま進まない (cilium-cni が見つからない)

```
plugin type="cilium-cni" failed (add):
  failed to find plugin "cilium-cni" in path [/opt/cni/bin]
```

Cilium が CNI プラグインを置く場所と、kubelet が探す場所がずれている。

kubelet が見るのは `/opt/cni/bin` なので、**Cilium の `cni.binPath` は指定してはいけない** (既定のままにする)。k3s のデータディレクトリ (`/var/lib/rancher/k3s/data/current/bin`) を指すと、置いた場所と探す場所が食い違ってこの状態になる。

```sh
sudo ls -la /opt/cni/bin/          # cilium-cni があるか
```

### Pod が Pending のまま進まない (CNI 未導入)

CNI が入っていない。Cilium の Pod を確認する。

```sh
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n kube-system logs -l k8s-app=cilium --tail=50
```

`--flannel-backend=none` にしてあるので、Cilium が立ち上がるまでは Pod ネットワークが存在しない。

### Cilium が起動しない

eBPF が使えるか確認する。

```sh
ls /sys/kernel/btf/vmlinux          # BTF。無いと Cilium は動かない
mount | grep bpf                    # bpf ファイルシステム
```

WSL2 のカーネルは `CONFIG_DEBUG_INFO_BTF=y` でビルドされているので通常は問題ない。

### Service に繋がらない

kube-proxy を無効にしてあるため、Cilium の kube-proxy 置き換えが効いていないと Service が解決されない。

```sh
cilium status | grep -i kubeproxy
```

### ノードが NotReady

`ip_forward` を確認する (`nix/modules/k3s.nix` で 1 にしている)。

```sh
cat /proc/sys/net/ipv4/ip_forward
```
