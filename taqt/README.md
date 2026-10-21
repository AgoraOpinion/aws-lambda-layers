# Taqt — Bref v2 PHP images

Fork of [brefphp/aws-lambda-layers](https://github.com/brefphp/aws-lambda-layers), branch `2.x`.

The API (`api.taqt.com`) runs on Bref v2, whose official images no longer follow the PHP patch releases.
This fork publishes the same images with an up-to-date PHP, until the API migrates to Bref v3.
PHP 8.2 security support ends on 31/12/2026: the migration must happen before.

The mechanism is the one of Bref: a GitHub release builds, tests and publishes the images,
the API pulls them with the `2` tag at each deployment.

## Changes compared to upstream `2.x`

- `php-82/Dockerfile`: `ARG VERSION_PHP` set to the PHP version we ship.
- `php-82/Dockerfile`: PHP sources downloaded from `https://www.php.net/distributions/`, the former URL no longer works (same fix as upstream 3.0.8).
- `Makefile`: `upload-to-ghcr-php-%` target, same images and tags as `upload-to-docker-hub` but pushed to `ghcr.io/agoraopinion`.
- `.github/workflows/release.yml`: PHP 8.2 ARM only, built on a GitHub ARM runner (instead of depot.dev), published to ghcr.io (instead of Docker Hub and the AWS layers).
- `.github/workflows/tests.yml`: removed, it relies on the depot.dev account of Bref. The release workflow runs the tests.

## Publish a new PHP version

1. Set the new version in `ARG VERSION_PHP` of `php-82/Dockerfile`, commit and push on `2.x`.
2. Create a GitHub release on `2.x`, tagged with the PHP version (e.g. `8.2.35`).
3. The `Release` workflow publishes `arm-php-82`, `arm-php-82-fpm`, `arm-php-82-console`, `arm-build-php-82` and `arm-php-82-fpm-dev` to `ghcr.io/agoraopinion`, tagged `2` and with the PHP version.
4. Deploy the API: its build pulls the new `2` images.

The packages must be public so the CI of the API can pull them without credentials.

## Sync with upstream

```bash
git remote add upstream https://github.com/brefphp/aws-lambda-layers.git
git fetch upstream 2.x
git merge upstream/2.x
```
