# 🐳 remote-docker-runner-action
GitHub Action to SSH into a remote server and run Docker containers with environment secrets. Ideal for deploying to self-hosted or on-premise environments.

## 🚀 Features

- ✅ Run Docker containers remotely over SSH
- ✅ Supports environment variables
- ✅ Private registry login support
- ✅ Deploy any image with custom ports and options

---

## 📦 Usage

### 🔧 Inputs

| Name             | Required | Description                                      |
|------------------|----------|--------------------------------------------------|
| `host`           | ✅       | Remote SSH host (IP or domain)                   |
| `username`       | ✅       | SSH username                                     |
| `private_key`    | ✅       | SSH private key (multi-line, base64-safe)        |
| `image`          | ✅       | Docker image name (e.g., `user/app`)             |
| `container_name` | ✅       | Docker container name                            |
| `docker_username`| ✅       | Docker registry username                         |
| `docker_password`| ✅       | Docker registry password                         |
| `registry`       | ❌       | Docker registry (default: `docker.io`)           |
| `tag`            | ❌       | Image tag (default: `latest`)                    |
| `docker_ports`   | ❌       | Port mappings (e.g., `-p 80:80`)                 |
| `docker_options` | ❌       | Additional Docker run options                    |
| `env_vars`       | ❌       | Environment variables (`- KEY=value`)            |

---

### 🧪 Example

```yaml
- name: Deploy to Remote Docker Host
  uses: thomasvjoseph/ssh-docker@v1.0.0
  with:
    host: ${{ secrets.SSH_HOST }}
    username: ${{ secrets.SSH_USER }}
    private_key: ${{ secrets.SSH_PRIVATE_KEY }}
    image: thomasjiitak/learn
    container_name: test-app
    docker_username: ${{ secrets.DOCKER_USERNAME }}
    docker_password: ${{ secrets.DOCKER_PASSWORD }}
    docker_ports: "-p 80:80"
    env_vars: |
      - KEY=${{ vars.KEY }}

```
⸻

🛡️ Security
	•	Use GitHub Secrets for sensitive values (SSH keys, credentials, etc.)
	•	Your private key should be multi-line compatible and correctly formatted (e.g., OpenSSH format)

⸻

🛠️ Requirements on Remote Host
	•	Docker must be installed and running
	•	SSH access should be configured for the given user

⸻

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for more details.

## Contributing

Feel free to open an issue or submit a pull request to improve the module.

## Author:  
thomas joseph
- [linkedin](https://www.linkedin.com/in/thomas-joseph-88792b132/)
- [medium](https://medium.com/@thomasvjoseph)