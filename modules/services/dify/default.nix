{config, ...}: let
  commonExtraOptions = ["--add-host=host.containers.internal:host-gateway"];
  envFile = [config.sops.templates."dify.env".path];
  pluginEnvFile = [config.sops.templates."dify-plugin.env".path];
  inherit (config.my.defaults) timezone domain;
in {
  sops.secrets.dify_db_password = {
    sopsFile = ../../../secrets/dify.yaml;
    key = "dify_db_password";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.dify_redis_password = {
    sopsFile = ../../../secrets/dify.yaml;
    key = "dify_redis_password";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.dify_secret_key = {
    sopsFile = ../../../secrets/dify.yaml;
    key = "dify_secret_key";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.dify_plugin_server_key = {
    sopsFile = ../../../secrets/dify.yaml;
    key = "dify_plugin_server_key";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.dify_plugin_inner_api_key = {
    sopsFile = ../../../secrets/dify.yaml;
    key = "dify_plugin_inner_api_key";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.templates."dify.env" = {
    owner = "root";
    mode = "0400";
    content = ''
      # Database
      DB_USERNAME=dify
      DB_PASSWORD=${config.sops.placeholder.dify_db_password}
      DB_HOST=host.containers.internal
      DB_PORT=5432
      DB_DATABASE=dify

      # Redis
      REDIS_HOST=host.containers.internal
      REDIS_PORT=6379
      REDIS_DB=0
      REDIS_PASSWORD=${config.sops.placeholder.dify_redis_password}
      CELERY_BROKER_URL=redis://:${config.sops.placeholder.dify_redis_password}@host.containers.internal:6379/0

      # App
      SECRET_KEY=${config.sops.placeholder.dify_secret_key}
      LOG_LEVEL=WARNING

      # Vector store
      VECTOR_STORE=weaviate
      WEAVIATE_ENDPOINT=http://host.containers.internal:8079

      # Storage
      STORAGE_TYPE=local
      STORAGE_LOCAL_PATH=/app/api/storage

      # Plugin daemon
      PLUGIN_DAEMON_URL=http://host.containers.internal:5002
      PLUGIN_DAEMON_KEY=${config.sops.placeholder.dify_plugin_server_key}
    '';
  };

  sops.templates."dify-plugin.env" = {
    owner = "root";
    mode = "0400";
    content = ''
      DB_USERNAME=dify
      DB_PASSWORD=${config.sops.placeholder.dify_db_password}
      DB_HOST=host.containers.internal
      DB_PORT=5432
      DB_DATABASE=dify_plugin
      REDIS_HOST=host.containers.internal
      REDIS_PORT=6379
      REDIS_PASSWORD=${config.sops.placeholder.dify_redis_password}
      SERVER_PORT=5002
      SERVER_KEY=${config.sops.placeholder.dify_plugin_server_key}
      DIFY_INNER_API_URL=http://host.containers.internal:5001
      DIFY_INNER_API_KEY=${config.sops.placeholder.dify_plugin_inner_api_key}
      PLUGIN_WORKING_PATH=/app/storage/cwd
      PLUGIN_STORAGE_TYPE=local
      PLUGIN_STORAGE_LOCAL_ROOT=/app/storage
      PLUGIN_INSTALLED_PATH=plugin
      PLUGIN_PACKAGE_CACHE_PATH=plugin_packages
      PLUGIN_MEDIA_CACHE_PATH=assets
      PLUGIN_REMOTE_INSTALLING_HOST=0.0.0.0
      PLUGIN_REMOTE_INSTALLING_PORT=5003
      FORCE_VERIFYING_SIGNATURE=false
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/dify 0755 root root -"
    "d /var/lib/dify/api 0755 root root -"
    "d /var/lib/dify/weaviate 0755 root root -"
    "d /var/lib/dify/plugin-daemon 0755 root root -"
  ];

  virtualisation.oci-containers.containers = {
    dify-weaviate = {
      autoStart = true;
      image = "semitechnologies/weaviate:1.26.1";
      ports = ["8079:8080"];
      environment = {
        QUERY_DEFAULTS_LIMIT = "25";
        AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED = "true";
        PERSISTENCE_DATA_PATH = "/var/lib/weaviate";
        DEFAULT_VECTORIZER_MODULE = "none";
        CLUSTER_HOSTNAME = "node1";
      };
      volumes = ["/var/lib/dify/weaviate:/var/lib/weaviate"];
    };

    dify-plugin-daemon = {
      autoStart = true;
      image = "langgenius/dify-plugin-daemon:0.6.0-local";
      environmentFiles = pluginEnvFile;
      volumes = ["/var/lib/dify/plugin-daemon:/app/storage"];
      ports = ["5002:5002"];
      extraOptions = commonExtraOptions;
    };

    dify-api = {
      autoStart = true;
      image = "langgenius/dify-api:1.0.0";
      environment = {
        TZ = timezone;
        MODE = "api";
      };
      environmentFiles = envFile;
      volumes = ["/var/lib/dify/api:/app/api/storage"];
      ports = ["5001:5001"];
      extraOptions = commonExtraOptions;
    };

    dify-worker = {
      autoStart = true;
      image = "langgenius/dify-api:1.0.0";
      environment = {
        TZ = timezone;
        MODE = "worker";
      };
      environmentFiles = envFile;
      volumes = ["/var/lib/dify/api:/app/api/storage"];
      extraOptions = commonExtraOptions;
    };

    dify-web = {
      autoStart = true;
      image = "langgenius/dify-web:1.0.0";
      environment = {
        TZ = timezone;
        CONSOLE_API_URL = "https://dify.${domain}";
        APP_API_URL = "https://dify.${domain}";
      };
      ports = ["127.0.0.1:3000:3000"];
      extraOptions = commonExtraOptions;
    };
  };
}
