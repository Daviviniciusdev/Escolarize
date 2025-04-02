export const root = true;
export const env = {
	es6: true,
	node: true,
};
export const eslintExtends = [
	"eslint:recommended",
	"google",
];
export const rules = {
	"quotes": ["error", "double"],
	"indent": ["error", 2],
	"object-curly-spacing": ["error", "always"],
	"linebreak-style": 0,
};
export const parserOptions = {
	"ecmaVersion": 2018,
};
