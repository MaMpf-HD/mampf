"use strict";(self.webpackChunkdoc=self.webpackChunkdoc||[]).push([[298],{3905:(e,t,n)=>{n.d(t,{Zo:()=>u,kt:()=>k});var r=n(67294);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function s(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,r,a=function(e,t){if(null==e)return{};var n,r,a={},o=Object.keys(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var i=r.createContext({}),c=function(e){var t=r.useContext(i),n=t;return e&&(n="function"==typeof e?e(t):s(s({},t),e)),n},u=function(e){var t=c(e.components);return r.createElement(i.Provider,{value:t},e.children)},d="mdxType",p={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},m=r.forwardRef((function(e,t){var n=e.components,a=e.mdxType,o=e.originalType,i=e.parentName,u=l(e,["components","mdxType","originalType","parentName"]),d=c(n),m=a,k=d["".concat(i,".").concat(m)]||d[m]||p[m]||o;return n?r.createElement(k,s(s({ref:t},u),{},{components:n})):r.createElement(k,s({ref:t},u))}));function k(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var o=n.length,s=new Array(o);s[0]=m;var l={};for(var i in t)hasOwnProperty.call(t,i)&&(l[i]=t[i]);l.originalType=e,l[d]="string"==typeof e?e:a,s[1]=l;for(var c=2;c<o;c++)s[c]=n[c];return r.createElement.apply(null,s)}return r.createElement.apply(null,n)}m.displayName="MDXCreateElement"},4662:(e,t,n)=>{n.r(t),n.d(t,{Highlight:()=>u,assets:()=>i,contentTitle:()=>s,default:()=>m,frontMatter:()=>o,metadata:()=>l,toc:()=>c});var r=n(87462),a=(n(67294),n(3905));const o={title:"Markdown Features"},s=void 0,l={unversionedId:"markdown-features",id:"markdown-features",title:"Markdown Features",description:"Docusaurus supports the Markdown syntax and has some additional features.",source:"@site/i18n/de/docusaurus-plugin-content-docs/current/markdown-features.mdx",sourceDirName:".",slug:"/markdown-features",permalink:"/de/docs/markdown-features",draft:!1,editUrl:"https://github.com/mampf-hd/mampf/edit/main/docs/docs/markdown-features.mdx",tags:[],version:"current",frontMatter:{title:"Markdown Features"}},i={},c=[{value:"Front Matter",id:"front-matter",level:2},{value:"Markdown links",id:"markdown-links",level:2},{value:"Markdown images",id:"markdown-images",level:2},{value:"Code Blocks",id:"code-blocks",level:2},{value:"Admonitions",id:"admonitions",level:2},{value:"React components",id:"react-components",level:2}],u=e=>{let{children:t,color:n}=e;return(0,a.kt)("span",{style:{backgroundColor:n,borderRadius:"2px",color:"#fff",padding:"0.2rem"}},t)},d={toc:c,Highlight:u},p="wrapper";function m(e){let{components:t,...n}=e;return(0,a.kt)(p,(0,r.Z)({},d,n,{components:t,mdxType:"MDXLayout"}),(0,a.kt)("p",null,"Docusaurus supports the ",(0,a.kt)("a",{parentName:"p",href:"https://daringfireball.net/projects/markdown/syntax"},"Markdown")," syntax and has some additional features."),(0,a.kt)("h2",{id:"front-matter"},"Front Matter"),(0,a.kt)("p",null,"Markdown documents can have associated metadata at the top called ",(0,a.kt)("a",{parentName:"p",href:"https://jekyllrb.com/docs/front-matter/"},"Front Matter"),":"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-md"},"---\nid: my-doc\ntitle: My document title\ndescription: My document description\nsidebar_label: My doc\n---\n\nMarkdown content\n")),(0,a.kt)("h2",{id:"markdown-links"},"Markdown links"),(0,a.kt)("p",null,"Regular Markdown links are supported using url paths or relative file paths."),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-md"},"Let's see how to [Create a page](/create-a-page).\n")),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-md"},"Let's see how to [Create a page](./create-a-page.md).\n")),(0,a.kt)("p",null,"Let's see how to ",(0,a.kt)("a",{parentName:"p",href:"./create-a-page.md"},"Create a page"),"."),(0,a.kt)("h2",{id:"markdown-images"},"Markdown images"),(0,a.kt)("p",null,"Regular Markdown images are supported."),(0,a.kt)("p",null,"Add an image at ",(0,a.kt)("inlineCode",{parentName:"p"},"static/img/docusaurus.png")," and use this Markdown declaration:"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-md"},"![Docusaurus logo](/img/docusaurus.png)\n")),(0,a.kt)("h2",{id:"code-blocks"},"Code Blocks"),(0,a.kt)("p",null,"Markdown code blocks are supported with Syntax highlighting."),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre"},'```jsx title="src/components/HelloDocusaurus.js"\nfunction HelloDocusaurus() {\n    return (\n        <h1>Hello, Docusaurus!</h1>\n    )\n}\n```\n')),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-jsx",metastring:'title="src/components/HelloDocusaurus.js"',title:'"src/components/HelloDocusaurus.js"'},"function HelloDocusaurus() {\n  return <h1>Hello, Docusaurus!</h1>;\n}\n")),(0,a.kt)("h2",{id:"admonitions"},"Admonitions"),(0,a.kt)("p",null,"Docusaurus has a special syntax to create admonitions and callouts:"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre"},":::tip My tip\n\nUse this awesome feature option\n\n:::\n\n:::danger Take care\n\nThis action is dangerous\n\n:::\n")),(0,a.kt)("admonition",{title:"My tip",type:"tip"},(0,a.kt)("p",{parentName:"admonition"},"Use this awesome feature option")),(0,a.kt)("admonition",{title:"Take care",type:"danger"},(0,a.kt)("p",{parentName:"admonition"},"This action is dangerous")),(0,a.kt)("h2",{id:"react-components"},"React components"),(0,a.kt)("p",null,"Thanks to ",(0,a.kt)("a",{parentName:"p",href:"https://mdxjs.com/"},"MDX"),", you can make your doc more interactive and use React components inside Markdown:"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-jsx"},"export const Highlight = ({children, color}) => (\n  <span\n    style={{\n      backgroundColor: color,\n      borderRadius: '2px',\n      color: 'red',\n      padding: '0.2rem',\n    }}>\n    {children}\n  </span>\n);\n\n<Highlight color=\"#25c2a0\">Docusaurus green</Highlight> and <Highlight color=\"#1877F2\">Facebook blue</Highlight> are my favorite colors.\n")),(0,a.kt)(u,{color:"#25c2a0",mdxType:"Highlight"},"Docusaurus green")," and ",(0,a.kt)(u,{color:"#1877F2",mdxType:"Highlight"},"Facebook blue")," are my favorite colors.")}m.isMDXComponent=!0}}]);