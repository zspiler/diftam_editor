BUILD_REPO="/Users/zanspiler/diploma/poc-web-preview";
cd ..;
flutter build web;
sed -i '' '/^[[:space:]]*<base href="\/">[[:space:]]*$/d' build/web/index.html;
cp -r build/web/* $BUILD_REPO;
cd $BUILD_REPO && git add . && git commit -m "update" && git push origin master;