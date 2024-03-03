# Docker Deluge Update PMP

This project contains a Docker image that is based on a Linux server and includes a cron job that runs a shell script to update port of deluge based in [Reddit Post](https://www.reddit.com/r/ProtonVPN/comments/10owypt/successful_port_forward_on_debian_wdietpi_using/)

Container based in linux server [Container](https://docs.linuxserver.io/images/docker-deluge/)

## Docker Compose

```yaml
version: "3.8"
services:
  deluge:
    image: ghcr.io/lulodev/docker-deluge-update-pmp:latest
    container_name: deluge
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - DELUGE_LOGLEVEL=error #optional
      - DELUGE_USER=cron
      - DELUGE_PASSWORD=cronpass
    volumes:
      - /path/to/deluge/config:/config
      - /path/to/your/downloads:/downloads
    ports:
      - 8112:8112
      - 6881:6881
      - 6881:6881/udp
      - 58846:58846 #optional
    restart: unless-stopped
```

## K3s

Example gluetun config [wiki](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/vpn-port-forwarding.md)

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gluetun-deployment
  labels:
    app: gluetun
spec:
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
  selector:
    matchLabels:
      app: gluetun
  template:
    metadata:
      labels:
        app: gluetun
    spec:
      containers:
        - name: gluetun
          image: ghcr.io/qdm12/gluetun # Optionally you can use the "qmcgaw/gluetun" image as well as specify what version of Gluetun you desire
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: "200m"
              memory: "512Mi"
          securityContext:
            allowPrivilegeEscalation: true
            privileged: true
            readOnlyRootFilesystem: false
            runAsNonRoot: false
            capabilities:
              add:
                - NET_ADMIN
          env:
            - name: TZ
              value: "Etc/UTC"

            - name: VPN_SERVICE_PROVIDER
              value: "custom"

            - name: VPN_TYPE
              value: "wireguard"

            - name: VPN_ENDPOINT_IP
              value: "0.0.0.0"

            - name: VPN_ENDPOINT_PORT
              value: "51820"

            - name: WIREGUARD_PUBLIC_KEY
              value: "==="

            - name: WIREGUARD_PRIVATE_KEY
              value: "==="

            - name: WIREGUARD_ADDRESSES
              value: "0.0.0.0/32"

            - name: VPN_PORT_FORWARDING
              value: "on"

            - name: VPN_PORT_FORWARDING_PROVIDER
              value: "YOUR_PROVIDER"

            - name: HEALTH_SUCCESS_WAIT_DURATION
              value: "3000s"

            - name: FIREWALL_DEBUG
              value: "on"
            - name: FIREWALL_INPUT_PORTS
              value: "8080"

          volumeMounts:
            - name: gluetun-config
              mountPath: /gluetun

        - name: deluge
          image: ghcr.io/lulodev/docker-deluge-update-pmp:latest
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: "200m"
              memory: "512Mi"
          ports:
            - containerPort: 8112
            - containerPort: 6881
            - containerPort: 6881
              protocol: UDP
            - containerPort: 58846
          env:
            - name: PUID
              value: "1000"
            - name: PGID
              value: "1000"
            - name: TZ
              value: "Etc/UTC"
            - name: DELUGE_LOGLEVEL
              value: "error"
            - name: DELUGE_USER
              value: cron
            - name: DELUGE_PASSWORD
              value: cronpass
          securityContext:
            allowPrivilegeEscalation: true
            privileged: true
            readOnlyRootFilesystem: false
            runAsNonRoot: false
          startupProbe:
            failureThreshold: 3
            tcpSocket:
              port: 8112
          volumeMounts:
            - name: deluge-config
              mountPath: /config
            - name: deluge-downloads
              mountPath: /media

      dnsPolicy: ClusterFirst
      hostNetwork: false
      restartPolicy: Always
      securityContext:
        fsGroupChangePolicy: Always
        runAsNonRoot: true
      setHostnameAsFQDN: false
      terminationGracePeriodSeconds: 30
      volumes:
        - name: gluetun-config
          persistentVolumeClaim:
            claimName: pvc-gluetun-config
        - name: deluge-config
          persistentVolumeClaim:
            claimName: pvc-deluge-config
        - name: deluge-downloads
          persistentVolumeClaim:
            claimName: pvc-deluge-downloads
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.