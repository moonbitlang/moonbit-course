course%.pdf:
	npx marp --theme custom.css --engine ./engine.mjs --pdf --allow-local-files --html -o course$*/lec$*.pdf -- course$*/lec$*.mbt.md

course%.pptx:
	npx marp --theme custom.css --engine ./engine.mjs --pptx --allow-local-files --html -- course$*/lec$*.md 

course%.watch:
	npx marp --theme custom.css --engine ./engine.mjs --watch --allow-local-files --html -- course$*/lec$*.md
