init:
	# Create symlink for pre-commit hook.
	ln -sf ../../tool/pre-commit.sh .git/hooks/pre-commit

install:
	# Install dev dependencies.
	npm install --global postcss-cli@2.3.2
	npm install --global postcss-apply
	npm install --global postcss-css-variables

deploy:
	./tool/deploy.sh
