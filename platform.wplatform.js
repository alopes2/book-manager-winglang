exports.Platform = class Platform {
  postSynth(config) {
    config.terraform.backend = {
      s3: {
        bucket: 'terraform-medium-api-notification',
        key: 'book-manager-winglang/state.tfstate',
      },
    };
    return config;
  }
};
