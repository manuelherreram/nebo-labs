# Task 09 — CI/CD Starter Pipeline with Jenkins

This lab sets up a **Jenkins Pipeline** that runs inside a Docker agent.  
It introduces a starter **CI/CD flow** with two stages (Build & Test), each containing multiple steps.

---

## What this pipeline does

- **Stage 1 — Build**
  - Runs inside a lightweight Docker container (`python:3.13-slim`).
  - Verifies Python version.
  - Installs basic packaging tools (`pip`, `setuptools`, `wheel`).

- **Stage 2 — Test**
  - Executes simple test commands (simulated).
  - Confirms that Python is working and outputs a success message.

- **Post actions**
  - Always logs pipeline completion.
  - Reports success ✅ or failure ❌.

---

## Jenkins setup

1. **Install Jenkins** (locally or in Docker).
2. Install the **Docker Pipeline Plugin** in Jenkins.
3. Configure a new pipeline job:
   - Repository: `https://github.com/manuelherreram/nebo-labs.git`
   - Branch: `main`
   - Script Path: `task09-cicd/Jenkinsfile`
   - Uncheck *Lightweight checkout*.
4. Run the job → Jenkins pulls the repo and executes the pipeline.

---

## Files in this folder

- `Jenkinsfile`: defines the CI pipeline using Docker agent.

---

## Example Jenkinsfile

```
pipeline {
    agent {
        docker { image 'python:3.13-slim' }
    }

    stages {
        stage('Build') {
            steps {
                echo "📦 Installing dependencies"
                sh 'python --version'
                sh 'pip install --upgrade pip setuptools wheel'
            }
        }

        stage('Test') {
            steps {
                echo "🧪 Running tests"
                sh 'echo "Pretend tests are running..."'
                sh 'python -c "print(\'All tests passed ✅\')"'
            }
        }
    }

    post {
        always { echo "Pipeline finished (success or failure)." }
        success { echo "✅ Build + Test completed successfully!" }
        failure { echo "❌ Something went wrong." }
    }
}
```

## How to test

Trigger the job in Jenkins.

Observe the logs:

Stage 1: shows Python version and dependency installation.

Stage 2: runs simulated tests.

The pipeline should finish with a success message.

## Mapping to the NEBo tasks
Continuous Delivery/Deployment (CD) basics: starter Jenkins pipeline.

Two stages with at least two steps each → satisfies acceptance criteria.

Uses Docker for a clean, reproducible environment.

Can be extended with packaging steps (e.g., PyPI upload) for more advanced workflows.
