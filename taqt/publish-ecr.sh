#!/usr/bin/env bash
# Builds the Bref v2 PHP 8.2 ARM images and pushes them to the ECR of each given AWS account.
#
# Usage: taqt/publish-ecr.sh <aws-profile> [<aws-profile>...]
#
# The PHP version is the one of php-82/Dockerfile (ARG VERSION_PHP), it is also the tag of the pushed images.
# An image tag already present in an ECR is never overwritten: bump the version instead.
set -euo pipefail

REGION=eu-west-3
IMAGES=(arm-build-php-82 arm-php-82 arm-php-82-fpm arm-php-82-console)

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <aws-profile> [<aws-profile>...]" >&2
    exit 1
fi
PROFILES=("$@")

if [ "$(uname -m)" != "arm64" ]; then
    echo "This script must run on an ARM machine (Apple Silicon): the PHP compilation under emulation is far too slow." >&2
    exit 1
fi

VERSION_PHP=$(sed -n 's/^ARG VERSION_PHP=//p' php-82/Dockerfile)
if [ -z "$VERSION_PHP" ]; then
    echo "Unable to read ARG VERSION_PHP from php-82/Dockerfile" >&2
    exit 1
fi
echo "PHP version: $VERSION_PHP"

# Check the credentials and the target tags before the long build
# Indexed like PROFILES, the bash 3 of macOS has no associative arrays
REGISTRIES=()
for PROFILE in "${PROFILES[@]}"; do
    ACCOUNT_ID=$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text)
    REGISTRIES+=("$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com")
    for IMAGE in "${IMAGES[@]}"; do
        if ! aws ecr describe-repositories --profile "$PROFILE" --region "$REGION" \
            --repository-names "bref/$IMAGE" >/dev/null; then
            echo "The ECR repository bref/$IMAGE is not reachable in the account $ACCOUNT_ID ($PROFILE)" >&2
            exit 1
        fi
        if aws ecr describe-images --profile "$PROFILE" --region "$REGION" --repository-name "bref/$IMAGE" \
            --image-ids imageTag="$VERSION_PHP" >/dev/null 2>&1; then
            echo "bref/$IMAGE:$VERSION_PHP already exists in the account $ACCOUNT_ID ($PROFILE)" >&2
            exit 1
        fi
    done
    echo "Account $ACCOUNT_ID ($PROFILE): OK"
done

make docker-images-php-82 CPU=arm

BUILT_VERSION=$(docker run --rm --platform linux/arm64 --entrypoint /opt/bin/php bref/arm-php-82-fpm -r 'echo PHP_VERSION;')
if [ "$BUILT_VERSION" != "$VERSION_PHP" ]; then
    echo "The built image runs PHP $BUILT_VERSION instead of $VERSION_PHP" >&2
    exit 1
fi

for i in "${!PROFILES[@]}"; do
    PROFILE=${PROFILES[$i]}
    REGISTRY=${REGISTRIES[$i]}
    aws ecr get-login-password --profile "$PROFILE" --region "$REGION" \
        | docker login --username AWS --password-stdin "$REGISTRY"
    for IMAGE in "${IMAGES[@]}"; do
        docker tag "bref/$IMAGE" "$REGISTRY/bref/$IMAGE:$VERSION_PHP"
        docker push "$REGISTRY/bref/$IMAGE:$VERSION_PHP"
    done
done

echo "PHP $VERSION_PHP pushed to: ${PROFILES[*]}"
