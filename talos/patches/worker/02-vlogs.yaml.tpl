machine:
  logging:
    destinations:
      - endpoint: "udp://127.0.0.1:6051/"
        format: "json_lines"
        extraTags:
          hostname: {{ .Node.Host }}
---
apiVersion: v1alpha1
kind: KmsgLogConfig
name: remote-log
url: tcp://host:6050/
