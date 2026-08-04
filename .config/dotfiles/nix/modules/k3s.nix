# ローカルの Kubernetes。GKE とオンプレの両方に移せるよう、k3s 独自の同梱物を
# 外して upstream に寄せてある。
#
# 有効にするホストだけが import する (k3s は常駐するため、全ホストには入れない)。
{ pkgs, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";

    # nixpkgs の更新でマイナーが上がらないよう固定する。本番のバージョンに
    # 合わせたいときはここを変える
    package = pkgs.k3s_1_36;

    # 既定の datastore は kine (SQLite) で、これが upstream との差が一番出る
    # ところ。clusterInit を立てると embedded etcd になる
    clusterInit = true;

    # k3s が同梱するものは外し、本番と同じ実装を自分で入れる。
    # helm-controller だけは残す - 下の autoDeployCharts を処理するのがそれ
    disable = [
      "traefik" # Ingress は ingress-nginx を使う
      "servicelb" # LoadBalancer は Cilium に任せる
      "local-storage" # StorageClass は本番の CSI に合わせて後で入れる
      "metrics-server" # 本番に合わせて必要なら入れ直す
    ];

    extraFlags = toString [
      # CNI と NetworkPolicy は Cilium が受け持つ
      "--flannel-backend=none"
      "--disable-network-policy"

      # kube-proxy も Cilium が置き換える。GKE の Dataplane V2 も
      # kube-proxy なしなので、そこに揃える
      "--disable-kube-proxy"

      # 一般ユーザーから kubectl を使えるようにする
      "--write-kubeconfig-mode=0644"
    ];

    autoDeployCharts = {
      # GKE の Dataplane V2 は Cilium ベースなので、CNI をこれに揃えると
      # NetworkPolicy まわりの挙動が本番と一致する
      cilium = {
        name = "cilium";
        repo = "https://helm.cilium.io";
        version = "1.20.0";
        hash = "sha256-xfATkSNg0aM09E7yXzbaWbo0FM20j0Zu4S0MT9/yeIM=";
        targetNamespace = "kube-system";

        # CNI がないと kubelet が Ready にならず、ノードに not-ready の taint が
        # 付く。それを tolerate しないと「CNI を入れる Job 自身が CNI がなくて
        # 動けない」というデッドロックになる。bootstrap を立てると、k3s は
        # この chart をクラスタ起動に必要なものとして扱い、taint を無視して
        # 先に流してくれる
        #
        # extraFieldDefinitions はリソースのトップレベルにマージされるので、
        # spec まで含めて指定しないとモジュールが生成する spec.bootstrap を
        # 上書きできない
        extraFieldDefinitions.spec.bootstrap = true;

        values = {
          # kube-proxy がいないので、API server の位置を直接教える必要がある
          kubeProxyReplacement = true;
          k8sServiceHost = "127.0.0.1";
          k8sServicePort = 6443;

          # cni.binPath は指定しない。k3s の kubelet はプラグインを
          # /opt/cni/bin から探すため、Cilium 側の既定のままにしておく必要が
          # ある。k3s のデータディレクトリを指すと、置いた場所と探す場所が
          # ずれて sandbox の作成が延々と失敗する

          # 単一ノードなので operator を冗長化しても待つだけになる
          operator.replicas = 1;

          ipam.mode = "kubernetes";
        };
      };

      ingress-nginx = {
        name = "ingress-nginx";
        repo = "https://kubernetes.github.io/ingress-nginx";
        version = "4.15.1";
        hash = "sha256-Pv8L0YFR1uaxxEFGNBBXFEPdoax4KSyxiTRmKN54Tww=";
        targetNamespace = "ingress-nginx";
        createNamespace = true;

        values = {
          controller = {
            # 本番は LoadBalancer になる。ローカルでそれを再現するには
            # Cilium の LB IPAM と L2 広告が要るが、WSL の仮想ネットワークでは
            # 広告先がないため、まずは NodePort で通す
            service.type = "NodePort";

            # 単一ノードなので複製しても同じノードに乗るだけ
            replicaCount = 1;

            # 単一ノード構成では Pod 同士の反発を切らないと Pending になる
            admissionWebhooks.enabled = true;
          };
        };
      };
    };
  };

  # Pod 間の通信に必要。WSL の既定は 0 になっている
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # k3s が書き出す kubeconfig をそのまま使う
  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    kubectx
    k9s
    stern
    cilium-cli

    # k3s の containerd を直接叩いてイメージを作るため。同じ containerd を
    # 使うので、ビルドしたイメージを push も import もせずに Pod から使える
    nerdctl
    buildkit
  ];

  # nerdctl build は自分ではビルドせず buildkitd に投げる。NixOS には
  # services.buildkit がないので自分で定義する。
  #
  # ワーカーを k3s の containerd にしているのがこの構成の要で、ビルドした
  # イメージが最初から k8s.io namespace に入るため、レジストリを経由せずに
  # そのまま Pod から参照できる。
  systemd.services.buildkitd = {
    description = "BuildKit daemon (k3s の containerd をワーカーにする)";
    wantedBy = [ "multi-user.target" ];
    after = [ "k3s.service" ];
    requires = [ "k3s.service" ];

    serviceConfig = {
      Type = "notify";
      ExecStart = ''
        ${pkgs.buildkit}/bin/buildkitd \
          --oci-worker=false \
          --containerd-worker=true \
          --containerd-worker-addr=/run/k3s/containerd/containerd.sock \
          --containerd-worker-namespace=k8s.io
      '';
      Restart = "always";
      RestartSec = "5s";
    };
  };

  # nerdctl から k3s の containerd を見に行かせる。namespace を k8s.io に
  # 合わせると、ビルドしたイメージが kubelet からそのまま見える
  environment.variables = {
    CONTAINERD_ADDRESS = "/run/k3s/containerd/containerd.sock";
    CONTAINERD_NAMESPACE = "k8s.io";
  };

  # k3s の containerd ソケットは root 所有で、nerdctl は一般ユーザーで起動すると
  # rootless モードに入って別のソケットを探しにいく。-E は上の環境変数を
  # sudo 越しに引き継ぐため
  environment.shellAliases.nerdctl = "sudo -E nerdctl";
}
