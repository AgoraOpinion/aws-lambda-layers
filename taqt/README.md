# Taqt — Bref v2 PHP images

Branch `taqt/2.x`, forked from the `2.x` branch of [brefphp/aws-lambda-layers](https://github.com/brefphp/aws-lambda-layers).

The API (`api.taqt.com`) runs on Bref v2, whose official images no longer follow the PHP patch releases.
This branch rebuilds them with an up-to-date PHP until the API migrates to Bref v3.

## Changes compared to upstream `2.x`

- `php-82/Dockerfile`: `ARG VERSION_PHP` set to the PHP version we ship.
- `php-82/Dockerfile`: PHP sources downloaded from `https://www.php.net/distributions/`, the former URL no longer works (same fix as upstream 3.0.8).

Only PHP 8.2 on ARM is maintained: it is the only runtime used by the API.

## Publish a new PHP version

Requirements: an ARM machine (Apple Silicon), Docker running, an AWS profile with ECR write access per account.

1. Set the new version in `ARG VERSION_PHP` of `php-82/Dockerfile`, commit and push on `taqt/2.x`.
2. Build and push to the accounts:

   ```bash
   taqt/publish-ecr.sh <aws-profile> [<aws-profile>...]
   ```

   The script checks every account before building (~4 min), then pushes `bref/arm-build-php-82`, `bref/arm-php-82`, `bref/arm-php-82-fpm` and `bref/arm-php-82-console` tagged with the PHP version.
   An existing tag is never overwritten.
3. In `api.taqt.com`, set `BREF_IMAGE_TAG` in `.github/workflows/deploy-lambdas-per-branch.yml` to the new version.

The images must be present in every account before the API uses them: test, preprod, preprod-rtos and prod.
The ECR repositories are created by the Terraform of `api.taqt.com` (`iac/common-resources/ecr.tf`).

## Sync with upstream

```bash
git remote add upstream https://github.com/brefphp/aws-lambda-layers.git
git fetch upstream 2.x
git merge upstream/2.x
```
