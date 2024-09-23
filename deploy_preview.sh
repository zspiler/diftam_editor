# Script which builds the web app, copies it to a different repo and pushes changes.
# Used to quickly re-deploy to Github Pages.

if [ -z "$DIFTAM_EDITOR_BUILD_REPO" ]; then
  echo "Environment variable DIFTAM_EDITOR_BUILD_REPO is not set";
  exit 1;
fi
flutter build web;
sed -i '' '/^[[:space:]]*<base href="\/">[[:space:]]*$/d' build/web/index.html;
cp -r build/web/* $DIFTAM_EDITOR_BUILD_REPO;
cd $DIFTAM_EDITOR_BUILD_REPO && git add . && git commit -m "update" && git push origin master;