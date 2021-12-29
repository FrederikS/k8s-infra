# k8s infra

## Setup k8s cluster client

1. Get server cert
2. Add cluster to your kubectl config

    ```shell
    kubectl config set-cluster pi --server https://k8s.fdk.codes:6443 --certificate-authority server-ca.crt --embed-certs
    ```

3. Get user cert and key from server
4. Add credentials to your kubectl config

    ```shell
    kubectl get secrets frederik -o jsonpath='{.data.tls\.crt}' | base64 --decode > frederik.crt
    kubectl get secrets frederik -o jsonpath='{.data.tls\.key}' | base64 --decode > frederik.key
    kubectl config set-credentials pi-frederik --client-certificate frederik.crt --client-key frederik.key --embed-certs
    ```

5. Add context to your kubectl config

    ```shell
    kubectl config set-context pi-frederik --cluster=pi --namespace=default --user=pi-frederik
    ```

6. Switch context and test your connection!

    ```shell
    kubectl config use-context pi-frederik
    kubectl get pods
    ```
