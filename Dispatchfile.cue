#!cue

common_env: [
  {
    name: "AWS_ACCESS_KEY_ID"
    valueFrom secretKeyRef name: "s3-config"
    valueFrom secretKeyRef key: "AWS_ACCESS_KEY_ID"
  },
  {
    name: "AWS_SECRET_ACCESS_KEY"
    valueFrom secretKeyRef name: "s3-config"
    valueFrom secretKeyRef key: "AWS_SECRET_ACCESS_KEY"
  },
  {
    name: "PLUGIN_PATH_STYLE"
    value: "true"
  },
  {
    name: "PLUGIN_MOUNT"
    value: "/root/.m2"
  },
  {
    name: "PLUGIN_BUCKET"
    value: "artifacts"
  },
  {
    name: "PLUGIN_ENDPOINT"
    value: "http://s3-us-east-1.pumpkin"
  },
  {
    name: "PLUGIN_REGION"
    value: "us-east-1"
  },...
]

resource "src-git": {
  type: "git"
  param url: "$(context.git.url)"
  param revision: "$(context.git.commit)"
}

resource "docker-image": {
  type: "image"
  param url: "cmays/hello-world-dispatch:$(context.build.name)"
  param digest: "$(inputs.resources.docker-image.digest)"
}

task "test": {
  inputs: ["src-git"]

  volumes: [
    {
      name: "cache-volume"
      emptyDir: {}
    }
  ]

  steps: [
    {
      name: "restore-cache"
      image: "meltwater/drone-cache"
      env: common_env +
      [
        {
          name: "PLUGIN_RESTORE"
          value: "true"
        }
      ]
      volumeMounts: [
        {
          name: "cache-volume"
          mountPath: "/root/.m2"
        }
      ]
    },
    {
      name: "test"
      image: "maven:3.6-jdk-8-slim"
      command: [ "mvn", "test" ]
      workingDir: "/workspace/src-git"
      volumeMounts: [
        {
          name: "cache-volume"
          mountPath: "/root/.m2"
        }
      ]
    },
    {
      name: "rebuild-cache"
      image: "meltwater/drone-cache"
      env: common_env +
      [
        {
          name: "PLUGIN_RESTORE"
          value: "false"
        },
        {
          name: "PLUGIN_REBUILD"
          value: "true"
        }
      ]

      volumeMounts: [
        {
          name: "cache-volume"
          mountPath: "/root/.m2"
        }
      ]
    }
  ]
}

task "build": {
  inputs: ["src-git"]
  outputs: ["docker-image"]

  volumes: [
    {
      name: "cache-volume"
      emptyDir: {}
    }
  ]

  steps: [
    {
      name: "restore-cache"
      image: "meltwater/drone-cache"
      env: common_env +
      [
        {
          name: "PLUGIN_RESTORE"
          value: "true"
        }
      ]
      volumeMounts: [
        {
          name: "cache-volume"
          mountPath: "/root/.m2"
        }
      ]
    },
    {
      name: "build"
      image: "maven:3.6-jdk-8-slim"
      command: [ "mvn", "verify" ]
      workingDir: "/workspace/src-git"
      volumeMounts: [
        {
          name: "cache-volume"
          mountPath: "/root/.m2"
        }
      ]
    },
    {
      name: "rebuild-cache"
      image: "meltwater/drone-cache"
      env: common_env +
      [
        {
          name: "PLUGIN_RESTORE"
          value: "false"
        },
        {
          name: "PLUGIN_REBUILD"
          value: "true"
        }
      ]

      volumeMounts: [
        {
          name: "cache-volume"
          mountPath: "/root/.m2"
        }
      ]
    },
    {
      name: "build-image"
      image: "gcr.io/kaniko-project/executor:v0.14.0"
      workingDir: "/workspace/src-git"
      args: [
        "--destination=$(outputs.resources.docker-image.url)",
        "--context=/workspace/src-git",
        "--oci-layout-path=/builder/home/image-outputs/docker-image",
        "--dockerfile=/workspace/src-git/Dockerfile"
      ],
      env: [
        {
          name: "DOCKER_CONFIG",
          value: "/builder/home/.docker"
        }
      ]
    }
  ]
}

actions: [
  {
    tasks: ["build"]
    on push branches: ["master"]
  },
  {
    tasks: ["test"]
    on push branches: ["!master"]
  }
]