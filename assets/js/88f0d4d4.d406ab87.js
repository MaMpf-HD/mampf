"use strict";(self.webpackChunkdoc=self.webpackChunkdoc||[]).push([[4874],{3905:(e,t,n)=>{n.d(t,{Zo:()=>o,kt:()=>k});var i=n(67294);function r(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function a(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);t&&(i=i.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,i)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?a(Object(n),!0).forEach((function(t){r(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):a(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function u(e,t){if(null==e)return{};var n,i,r=function(e,t){if(null==e)return{};var n,i,r={},a=Object.keys(e);for(i=0;i<a.length;i++)n=a[i],t.indexOf(n)>=0||(r[n]=e[n]);return r}(e,t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(i=0;i<a.length;i++)n=a[i],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(r[n]=e[n])}return r}var d=i.createContext({}),s=function(e){var t=i.useContext(d),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},o=function(e){var t=s(e.components);return i.createElement(d.Provider,{value:t},e.children)},m="mdxType",g={inlineCode:"code",wrapper:function(e){var t=e.children;return i.createElement(i.Fragment,{},t)}},c=i.forwardRef((function(e,t){var n=e.components,r=e.mdxType,a=e.originalType,d=e.parentName,o=u(e,["components","mdxType","originalType","parentName"]),m=s(n),c=r,k=m["".concat(d,".").concat(c)]||m[c]||g[c]||a;return n?i.createElement(k,l(l({ref:t},o),{},{components:n})):i.createElement(k,l({ref:t},o))}));function k(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var a=n.length,l=new Array(a);l[0]=c;var u={};for(var d in t)hasOwnProperty.call(t,d)&&(u[d]=t[d]);u.originalType=e,u[m]="string"==typeof e?e:r,l[1]=u;for(var s=2;s<a;s++)l[s]=n[s];return i.createElement.apply(null,l)}return i.createElement.apply(null,n)}c.displayName="MDXCreateElement"},92671:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>d,contentTitle:()=>l,default:()=>g,frontMatter:()=>a,metadata:()=>u,toc:()=>s});var i=n(87462),r=(n(67294),n(3905));const a={title:"Quizfrage bearbeiten"},l=void 0,u={unversionedId:"edit-question",id:"edit-question",title:"Quizfrage bearbeiten",description:"Auf der Seite \u201eFrage bearbeiten\u201c kann man eine bereits angelegte Frage bearbeiten, d.h. den Fragetext, den L\xf6sungshinweis und die Antwortm\xf6glichkeiten \xe4ndern sowie den Typ und den Schwierigkeitsgrad der Frage einstellen. Au\xdferdem kann man der Frage das Attribut \u201eunabh\xe4ngig\u201c zuweisen, wodurch sie bei Selbsttests ber\xfccksichtigt wird.",source:"@site/i18n/de/docusaurus-plugin-content-docs-mampf-pages/current/edit-question.md",sourceDirName:".",slug:"/edit-question",permalink:"/mampf/mampf-pages/edit-question",draft:!1,editUrl:"https://github.com/mampf-hd/mampf/edit/main/docs/mampf-pages/edit-question.md",tags:[],version:"current",frontMatter:{title:"Quizfrage bearbeiten"}},d={},s=[{value:"Navigation",id:"navigation",level:2},{value:"Bereiche der Seite",id:"bereiche-der-seite",level:2},{value:"Bedienelemente und m\xf6gliche Aktionen auf dieser Seite",id:"bedienelemente-und-m\xf6gliche-aktionen-auf-dieser-seite",level:2},{value:"Kopf",id:"kopf",level:3},{value:"Basisdaten",id:"basisdaten",level:3},{value:"Antworten (Multiple-Choice-Frage)",id:"antworten-multiple-choice-frage",level:3},{value:"Box \u201eNeue Antwort\u201c",id:"box-neue-antwort",level:4},{value:"Box \u201eBearbeiten\u201c",id:"box-bearbeiten",level:4},{value:"L\xf6sung (Frage mit freier Antwort)",id:"l\xf6sung-frage-mit-freier-antwort",level:3},{value:"Kopie erstellen",id:"kopie-erstellen",level:3},{value:"Verwandte Seite",id:"verwandte-seite",level:2}],o={toc:s},m="wrapper";function g(e){let{components:t,...a}=e;return(0,r.kt)(m,(0,i.Z)({},o,a,{components:t,mdxType:"MDXLayout"}),(0,r.kt)("p",null,"Auf der Seite \u201eFrage bearbeiten\u201c kann man eine bereits angelegte Frage bearbeiten, d.h. den Fragetext, den L\xf6sungshinweis und die Antwortm\xf6glichkeiten \xe4ndern sowie den Typ und den Schwierigkeitsgrad der Frage einstellen. Au\xdferdem kann man der Frage das Attribut \u201eunabh\xe4ngig\u201c zuweisen, wodurch sie bei Selbsttests ber\xfccksichtigt wird."),(0,r.kt)("p",null,"Zum Anlegen von Quizfragen siehe den ",(0,r.kt)("a",{parentName:"p",href:"quiz-editor"},"Quizeditor"),". Veranstaltungseditor","*","innen steht dazu auch die Seite ",(0,r.kt)("a",{parentName:"p",href:"ed-edit-event-series"},"\u201eVeranstaltung bearbeiten\u201c")," (also ",(0,r.kt)("a",{parentName:"p",href:"ed-edit-seminar"},"\u201eSeminar bearbeiten\u201c")," oder ",(0,r.kt)("a",{parentName:"p",href:"ed-edit-lecture"},"\u201eVorlesung bearbeiten\u201c"),") zur Verf\xfcgung. Moduleditor*innen k\xf6nnen Fragen auch auf der Seite ",(0,r.kt)("a",{parentName:"p",href:"ed-edit-module"},"\u201eModul bearbeiten\u201c")," anlegen."),(0,r.kt)("p",null,"Zum Verfassen eines Inhaltstextes und zum Hinzuf\xfcgen von Dateien (Videos, PDFs und externen Links) und Assoziationen (zu Veranstaltungen, Modulen, Lektionen, Vortr\xe4gen, Tags und Medien) siehe ",(0,r.kt)("a",{parentName:"p",href:"edit-medium-question"},"\u201eFrage bearbeiten\u201c (Medium)"),"."),(0,r.kt)("p",null,(0,r.kt)("img",{src:n(5604).Z,width:"1034",height:"905"})),(0,r.kt)("h2",{id:"navigation"},"Navigation"),(0,r.kt)("p",null,"Die Seite \u201eFrage bearbeiten\u201c erreicht man entweder \xfcber den ",(0,r.kt)("a",{parentName:"p",href:"quiz-editor"},"Quizeditor")," oder die Seite ",(0,r.kt)("a",{parentName:"p",href:"edit-medium-question"},"\u201eFrage bearbeiten\u201c (Medium)"),". Dazu muss die Frage bereits angelegt worden sein. Zum Anlegen von Fragen siehe den ",(0,r.kt)("a",{parentName:"p",href:"quiz-editor"},"Quizeditor")," und die Seiten ",(0,r.kt)("a",{parentName:"p",href:"ed-edit-event-series"},"\u201eVeranstaltung bearbeiten\u201c")," und ",(0,r.kt)("a",{parentName:"p",href:"ed-edit-module"},"\u201eModul bearbeiten\u201c")," (nur bei Editor","*","innen)."),(0,r.kt)("ul",null,(0,r.kt)("li",null,(0,r.kt)("a",{href:"/mampf/de/mampf-pages/quiz-editor",target:"_self"},(0,r.kt)("b",null,"Quizeditor"))),"Im Quizgraphen klickt man auf ",(0,r.kt)("button",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-regular.png",height:"12",class:"img"})),". Daraufhin erscheinen andere Buttons neben der \xdcberschrift der Box \u201eQuizgraph\u201c. Sofern man Bearbeitungsrechte f\xfcr die Frage hat, ist darunter auch der Button ",(0,r.kt)("button",null,"Bearbeiten"),", der einen auf die Seite \u201eFrage bearbeiten\u201c f\xfchrt.",(0,r.kt)("li",null,(0,r.kt)("a",{href:"/mampf/de/mampf-pages/edit-medium-question",target:"_self"},(0,r.kt)("b",null,"Seite \u201eFrage bearbeiten\u201c"))),"In der Box \u201eDokumente\u201c klickt man bei \u201eQuiz-Frage\u201c auf ",(0,r.kt)("button",null,"Bearbeiten"),", wodurch man auf die Seite \u201eFrage bearbeiten\u201c gelangt."),(0,r.kt)("p",null,"Wenn man den Weg \xfcber den Quizeditor w\xe4hlt, gelangt man auf eine Unterseite des Quiz'. Steuert man die Seite hingegen \xfcber die Seite \u201eFrage bearbeiten\u201c (Medium) an, gelangt man zu einer unabh\xe4ngigen Seite. Die beiden Seiten unterscheiden sich nur darin, dass der Button ",(0,r.kt)("button",null,"zum Medium")," zu unterschiedlichen Seiten f\xfchrt und die Unterseite des Quiz' \xfcber die zus\xe4tzlichen Buttons ",(0,r.kt)("button",null,"Quiz spielen")," und ",(0,r.kt)("button",null,"Bearbeitung beenden")," verf\xfcgt."),(0,r.kt)("h2",{id:"bereiche-der-seite"},"Bereiche der Seite"),(0,r.kt)("p",null,"Die Seite \u201eQuizfrage bearbeiten\u201c gliedert sich in zwei Teilbereiche: die eigentliche Seite \u201eQuizfrage bearbeiten\u201c und die ",(0,r.kt)("a",{parentName:"p",href:"/mampf/mampf-pages/nav-bar"},"Navigationsleiste"),". Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite."),(0,r.kt)("table",null,(0,r.kt)("thead",{parentName:"table"},(0,r.kt)("tr",{parentName:"thead"},(0,r.kt)("th",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_complete_navbar.png",height:"300"})),(0,r.kt)("th",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_complete_eigentliche_seite.png",height:"300"})))),(0,r.kt)("tbody",{parentName:"table"},(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:"center"},"Navigationsleiste"),(0,r.kt)("td",{parentName:"tr",align:"center"},"Eigentliche Seite")))),(0,r.kt)("p",null,"Die eigentliche Seite besteht aus dem Kopf und den Boxen \u201eBasisdaten\u201c und \u201eAntworten\u201c (bei Multiple-Choice-Fragen) bzw. \u201eL\xf6sung\u201c (bei Fragen mit freier Antwort). Diese Bereiche sind in den folgenden Screenshots hervorgehoben."),(0,r.kt)("table",null,(0,r.kt)("thead",{parentName:"table"},(0,r.kt)("tr",{parentName:"thead"},(0,r.kt)("th",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_bearbeiten_quiz_kopf.png",height:"500"})),(0,r.kt)("th",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_bearbeiten_quiz_basisdaten.png",height:"500"})))),(0,r.kt)("tbody",{parentName:"table"},(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:"center"},"Kopf"),(0,r.kt)("td",{parentName:"tr",align:"center"},"Basisdaten")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_bearbeiten_quiz_antworten.png",height:"500"})),(0,r.kt)("td",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_bearbeiten_quiz_lsg_green.png",height:"500"}))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:"center"},"Antworten (Multiple-Choice-Frage)"),(0,r.kt)("td",{parentName:"tr",align:"center"},"L\xf6sung (Frage mit freier Antwort)")))),(0,r.kt)("h2",{id:"bedienelemente-und-m\xf6gliche-aktionen-auf-dieser-seite"},"Bedienelemente und m\xf6gliche Aktionen auf dieser Seite"),(0,r.kt)("p",null,"Auf der Seite \u201eQuizfrage bearbeiten\u201c kommen Bedienelemente in den Bereichen Kopf, Basisdaten und Antworten bzw. L\xf6sung vor. Diese werden nun bereichsweise beschrieben."),(0,r.kt)("h3",{id:"kopf"},"Kopf"),(0,r.kt)("p",null,"Je nachdem auf welchen Weg man die Seite erreicht hat, stehen im Bereich Kopf unterschiedliche Bedienelemente zur Verf\xfcgung, wobei es sich jeweils um Navigationselemente handelt. Hat man den Weg \xfcber den ",(0,r.kt)("a",{parentName:"p",href:"quiz-editor"},"Quizeditor")," gew\xe4hlt, sind drei Buttons vorhanden. In diesem Fall steht in der \xdcberschift \u201eQuiz\u201c. Ist man \xfcber die ",(0,r.kt)("a",{parentName:"p",href:"edit-medium-question"},"Bearbeitungsseite des Mediums Frage")," gekommen, gibt es nur den Button ",(0,r.kt)("button",null,"zum Medium"),". Dies erkennt man auch daran, dass in der \xdcberschrift \u201eFrage\u201c vorkommt. Die nun folgenden Screenshots zeigen die unabh\xe4ngige Seite und die Quizunterseite \u201eQuizfrage bearbeiten\u201c. Die zus\xe4tzlichen Buttons der Quizunterseite sind im nachfolgenden Screenshot orange eingezeichnet."),(0,r.kt)("table",null,(0,r.kt)("thead",{parentName:"table"},(0,r.kt)("tr",{parentName:"thead"},(0,r.kt)("th",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_bearbeiten.png",width:"500"})),(0,r.kt)("th",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_bearbeiten_quiz_markiert.png",width:"500"})))),(0,r.kt)("tbody",{parentName:"table"},(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:"center"},"Unabh\xe4ngige Seite (erreicht \xfcber die Bearbeitungsseite des Mediums Frage)"),(0,r.kt)("td",{parentName:"tr",align:"center"},"Unterseite des Quiz' (erreicht \xfcber den Quizeditor)")))),(0,r.kt)("p",null,"Die folgenden Bedienelemente sind verf\xfcgbar:"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{href:"/mampf/de/mampf-pages/edit-quiz",target:"_self"},(0,r.kt)("button",{name:"button"},"zum Medium"))," (bei der Unterseite des Quiz') bzw. ",(0,r.kt)("a",{href:"/mampf/de/mampf-pages/edit-medium-question",target:"_self"},(0,r.kt)("button",{name:"button"},"zum Medium"))," (bei der unabh\xe4ngigen Seiten) Wechsel auf die Seite ",(0,r.kt)("a",{href:"/mampf/de/mampf-pages/edit-quiz",target:"_self"},"\u201eQuiz bearbeiten\u201c")," (bei der Unterseite des Quiz') bzw. ",(0,r.kt)("a",{href:"/mampf/de/mampf-pages/edit-medium-question",target:"_self"},"\u201eFrage bearbeiten\u201c (Medium)")," (bei der unabh\xe4ngigen Seiten)."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",{name:"button"},"Quiz spielen")," (nur bei der Unterseite des Quiz') \xd6ffne das Quiz in der Nutzeransicht. Dazu muss der Quizgraph strukturell fehlerfrei sein."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{href:"/mampf/de/mampf-pages/quiz-editor",target:"_self"},(0,r.kt)("button",{name:"button"},"Bearbeitung beenden"))," (nur bei der Unterseite des Quiz') Wechsel zum ",(0,r.kt)("a",{href:"/mampf/de/mampf-pages/quiz-editor",target:"_self"},"\u201eQuizeditor\u201c"),". Dabei werden nicht gespeicherte \xc4nderungen nicht \xfcbernommen.")),(0,r.kt)("h3",{id:"basisdaten"},"Basisdaten"),(0,r.kt)("p",null,"In der Box \u201eBasisdaten\u201c k\xf6nnen die Texte zur Frage und zu L\xf6sungshinweisen bearbeitet werden. Au\xdferdem kann der Typ, der Schwierigkeitsgrad und die Ber\xfccksichtigung bei der Generierung von Selbsttests eingestellt werden."),(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_frage_bearbeiten_basisdaten.png",width:"800"}),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"Speichern")," \xdcbernimm die vorgenommenen \xc4nderungen. Dieser Button erscheint erst, nachdem etwas in der Box \u201eBasisdaten\u201c bearbeitet worden ist."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"Verwerfen")," Verwirf die vorgenommenen \xc4nderungen. Dieser Button erscheint erst, nachdem etwas in der Box \u201eBasisdaten\u201c bearbeitet worden ist."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,(0,r.kt)("p",null,(0,r.kt)("label",{for:"fname"},"LaTeX"),(0,r.kt)("br",null),(0,r.kt)("input",{type:"text",id:"fname",name:"fname"}),(0,r.kt)("br",null)))," Eingabefeld f\xfcr den Fragetext. Um LaTeX zu verwenden, setze den gew\xfcnschten Text zwischen $-Zeichen. Beim Fragetyp ",(0,r.kt)("i",null,"freie Antwort")," k\xf6nnen Parameter durch $\\para{parameter,[start..stop]}$ definiert werden. Der Parameter sollte in der L\xf6sung vorkommen.",(0,r.kt)("table",null,(0,r.kt)("tr",null,(0,r.kt)("td",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_freie_antwort_parameter.png",width:"850"}))))),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,"Typ: ",(0,r.kt)("input",{type:"radio",id:"de",name:"lang",checked:!0}),(0,r.kt)("label",{for:"de"}," Multiple Choice "),(0,r.kt)("input",{type:"radio",id:"eng",name:"lang"}),(0,r.kt)("label",{for:"eng"}," freie Antwort")),(0,r.kt)("br",null),"Radiobuttons zur Festlegung des Fragetyps. Zur Auswahl stehen ",(0,r.kt)("i",null,"Multiple Choice")," und ",(0,r.kt)("i",null,"freie Antwort"),". Die hier getroffene Wahl bestimmt, ob die Box \u201eAntworten\u201c oder \u201eL\xf6sung\u201c verf\xfcgbar ist. Bei ",(0,r.kt)("i",null,"Multiple Choice")," k\xf6nnen mehrere falsche und richtige Antwortm\xf6glichkeiten angelegt werden. Bei ",(0,r.kt)("i",null,"freie Antwort")," kann ein Ausdruck, eine Menge, ein Tupel oder eine Matrix als L\xf6sung festgelegt werden."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,"Schwierigkeitsgrad: ",(0,r.kt)("input",{type:"radio",id:"easy",name:"lang"}),(0,r.kt)("label",{for:"easy"}," leicht "),(0,r.kt)("input",{type:"radio",id:"med",name:"lang"}),(0,r.kt)("label",{for:"med"}," mittel"),(0,r.kt)("input",{type:"radio",id:"hard",name:"lang"}),(0,r.kt)("label",{for:"hard"}," schwer")),(0,r.kt)("br",null),"Radiobuttons zur Festlegung des Schwierigkeitsgrads der Frage. Zur Auswahl stehen ",(0,r.kt)("i",null,"leicht"),", ",(0,r.kt)("i",null,"mittel")," und ",(0,r.kt)("i",null,"schwer"),"."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,(0,r.kt)("input",{type:"checkbox",id:"up",name:"sub"}),(0,r.kt)("label",{for:"up"}," Frage ist unabh\xe4ngig"),(0,r.kt)("br",null))," Checkbox. Setze den Haken, um der Frage das Attribut \u201eunabh\xe4ngig\u201c zuzuweisen. Infolgedessen wird sie beim Erstellen von Selbsttests ber\xfccksichtigt."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,(0,r.kt)("p",null,(0,r.kt)("label",{for:"fname"},"L\xf6sungshinweis"),(0,r.kt)("br",null),(0,r.kt)("input",{type:"text",id:"fname",name:"fname"}),(0,r.kt)("br",null)))," Eingabefeld f\xfcr den L\xf6sungshinweis. Um LaTeX zu verwenden, setze den gew\xfcnschten Text zwischen $-Zeichen. Der Hinweis kann beim Bearbeiten der Frage eingeblendet werden. Dazu klickt man oben rechts auf ",(0,r.kt)("button",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/question-circle-regular.png",height:"12",class:"img"})),".",(0,r.kt)("table",null,(0,r.kt)("tr",null,(0,r.kt)("td",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_lsg.hinweis.png",width:"850"}))),(0,r.kt)("tr",null,(0,r.kt)("td",{colspan:"2",text:!0,align:"center"},"Der Button ",(0,r.kt)("button",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/question-circle-regular.png",height:"12",class:"img"}))," zum Einblenden des Hinweises befindet sich oben rechts.")),(0,r.kt)("tr",null,(0,r.kt)("td",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_lsg.hinweis_sichtbar.png",width:"850"}))),(0,r.kt)("tr",null,(0,r.kt)("td",{colspan:"2",text:!0,align:"center"},"Der Hinweis wird unter der Frage angezeigt.")))),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"Kopie erstellen")," \xd6ffne das Dialogfenster \u201eKopie erstellen\u201c, um die ausgew\xe4hlte Frage zu kopieren. Davon sollte m\xf6glichst NICHT Gebrauch gemacht werden, da Duplikate die Datenbankpflege erschweren. Bei fehlenden Bearbeitungsrechten f\xfcr die Frage, sollte eine Person mit entsprechenden Rechten beim Finden von Fehlern kontaktiert werden.")),(0,r.kt)("h3",{id:"antworten-multiple-choice-frage"},"Antworten (Multiple-Choice-Frage)"),(0,r.kt)("p",null,"Wenn in der Box \u201eBasisdaten\u201c der Fragetyp \u201eMultiple Choice\u201c ausgew\xe4hlt ist, wird die Box \u201eAntworten\u201c auf der rechten Seite angezeigt. Dort k\xf6nnen neue Antworten angelegt und bereits vorhandene bearbeitet oder gel\xf6scht werden. Zun\xe4chst gibt es drei unterschiedliche Buttons in dieser Box."),(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_frage_bearbeiten_antworten.png",width:"800"}),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"Antwort hinzuf\xfcgen")," \xd6ffne die Box \u201eNeue Antwort\u201c und lege dort eine neue Antwort an."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"Bearbeiten")," Klappe die Bearbeitungsansicht der gew\xe4hlten Antwort aus und \xe4ndere dort die Korrektheit, den Antworttext oder die Erkl\xe4rung."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"L\xf6schen")," L\xf6sche die gew\xe4hlte Antwort.")),(0,r.kt)("h4",{id:"box-neue-antwort"},"Box \u201eNeue Antwort\u201c"),(0,r.kt)("p",null,"Die Box \u201eNeue Antwort\u201c erscheint innerhalb der Box \u201eAntworten\u201c, nachdem man auf ",(0,r.kt)("button",null,"Antwort hinzuf\xfcgen")," geklickt hat. Dort gibt Radiobuttons, zwei Textfelder und zwei einfache Buttons."),(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_frage_bearbeiten_antwort_hinzufuegen.png",width:"800"}),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,"Korrektheit: ",(0,r.kt)("input",{type:"radio",id:"right",name:"lang",checked:!0}),(0,r.kt)("label",{for:"right"}," wahr "),(0,r.kt)("input",{type:"radio",id:"wrong",name:"lang"}),(0,r.kt)("label",{for:"wrong"}," falsch")),(0,r.kt)("br",null),"Radiobuttons zur Festlegung der Korrektheit der Antwort. Zur Auswahl stehen ",(0,r.kt)("i",null,"wahr")," und ",(0,r.kt)("i",null,"falsch"),". Der voreingestellte Wert ist ",(0,r.kt)("i",null,"wahr"),"."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,(0,r.kt)("p",null,(0,r.kt)("label",{for:"fname"},"Text"),(0,r.kt)("br",null),(0,r.kt)("input",{type:"text",id:"fname",name:"fname"}),(0,r.kt)("br",null)))," Eingabefeld f\xfcr den Antworttext. Um LaTeX zu verwenden, setze den gew\xfcnschten Text zwischen $-Zeichen."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,(0,r.kt)("p",null,(0,r.kt)("label",{for:"fname"},"Erkl\xe4rung"),(0,r.kt)("br",null),(0,r.kt)("input",{type:"text",id:"fname",name:"fname"}),(0,r.kt)("br",null)))," Eingabefeld f\xfcr die Erkl\xe4rung. Um LaTeX zu verwenden, setze den gew\xfcnschten Text zwischen $-Zeichen. Dieser Text wird erst angezeigt, nachdem die Frage beantwortet wurde.",(0,r.kt)("table",null,(0,r.kt)("tr",null,(0,r.kt)("td",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quiz_erklaerung.png",width:"850"}))),(0,r.kt)("tr",null,(0,r.kt)("td",{colspan:"2",text:!0,align:"center"},"Der Button ",(0,r.kt)("button",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/question-circle-regular.png",height:"12",class:"img"}))," zum Einblenden der Erkl\xe4rung befindet sich bei jeder Antwortm\xf6glichkeit oben rechts.")))),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"Speichern")," Speichere die neue Antwort. Sie wird dann wie die anderen bereits angelegten Antworten anzeigt."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"Abbrechen")," Schlie\xdfe die Box \u201eNeue Antwort\u201c, ohne eine neue Antwort anzulegen.")),(0,r.kt)("h4",{id:"box-bearbeiten"},"Box \u201eBearbeiten\u201c"),(0,r.kt)("p",null,"Zu einer vorhandenen Antwort klappen Bedienelemente zur Bearbeitung aus, nachdem man auf den zur Antwort geh\xf6renden Button ",(0,r.kt)("button",null,"Bearbeiten")," geklickt hat. Bei den Bedienelementen handelt es sich um Radiobuttons, zwei Textfelder und drei einfache Buttons."),(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_frage_bearbeiten_antwort_bearbeiten.png",width:"800"}),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"Verwerfen")," Verwirf alle \xc4nderungen und minimiere die Antwortbox."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"L\xf6schen")," L\xf6sche die Antwort. Dabei wird die Box zur Antwort entfernt."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,"Korrektheit: ",(0,r.kt)("input",{type:"radio",id:"right",name:"lang",checked:!0}),(0,r.kt)("label",{for:"right"}," wahr "),(0,r.kt)("input",{type:"radio",id:"wrong",name:"lang"}),(0,r.kt)("label",{for:"wrong"}," falsch")),(0,r.kt)("br",null),"Radiobuttons zur Festlegung der Korrektheit der Antwort. Zur Auswahl stehen ",(0,r.kt)("i",null,"wahr")," und ",(0,r.kt)("i",null,"falsch"),"."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,(0,r.kt)("p",null,(0,r.kt)("label",{for:"fname"},"Text"),(0,r.kt)("br",null),(0,r.kt)("input",{type:"text",id:"fname",name:"fname"}),(0,r.kt)("br",null)))," Eingabefeld f\xfcr den Antworttext. Um LaTeX zu verwenden, setze den gew\xfcnschten Text zwischen $-Zeichen."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("form",null,(0,r.kt)("p",null,(0,r.kt)("label",{for:"fname"},"Erkl\xe4rung"),(0,r.kt)("br",null),(0,r.kt)("input",{type:"text",id:"fname",name:"fname"}),(0,r.kt)("br",null)))," Eingabefeld f\xfcr die Erkl\xe4rung. Um LaTeX zu verwenden, setze den gew\xfcnschten Text zwischen $-Zeichen. Dieser Text wird erst angezeigt, nachdem die Frage beantwortet wurde.",(0,r.kt)("table",null,(0,r.kt)("tr",null,(0,r.kt)("td",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quiz_erklaerung.png",width:"850"}))),(0,r.kt)("tr",null,(0,r.kt)("td",{colspan:"2",text:!0,align:"center"},"Der Button ",(0,r.kt)("button",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/question-circle-regular.png",height:"12",class:"img"}))," zum Einblenden der Erkl\xe4rung befindet sich bei jeder Antwortm\xf6glichkeit oben rechts.")))),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("button",null,"Speichern")," \xdcbernimm die vorgenommenen \xc4nderungen und minimiere die Antwortbox.")),(0,r.kt)("h3",{id:"l\xf6sung-frage-mit-freier-antwort"},"L\xf6sung (Frage mit freier Antwort)"),(0,r.kt)("p",null,"Wenn in der Box \u201eBasisdaten\u201c der Fragetyp \u201efreie Antwort\u201c ausgew\xe4hlt ist, wird die Box \u201eL\xf6sung\u201c auf der rechten Seite angezeigt. Dort k\xf6nnen der L\xf6sungstyp, die L\xf6sung und eine Erkl\xe4rung angelegt, bearbeitet oder gel\xf6scht werden. Der gew\xe4hlte Antworttyp bestimmt das Aussehen und die Bedienelemente der Box \u201eL\xf6sung\u201c. Zur Auswahl stehen die Antworttypen ",(0,r.kt)("em",{parentName:"p"},"Ausdruck"),", ",(0,r.kt)("em",{parentName:"p"},"Matrix"),", ",(0,r.kt)("em",{parentName:"p"},"Tupel")," und ",(0,r.kt)("em",{parentName:"p"},"Menge"),". Die dazu korrespondierenden  Ansichten sind in der nun folgenden Tabelle aufgef\xfchrt."),(0,r.kt)("table",null,(0,r.kt)("thead",{parentName:"table"},(0,r.kt)("tr",{parentName:"thead"},(0,r.kt)("th",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_freie_antwort_ausdruck.png"})),(0,r.kt)("th",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_freie_antwort_matrix.png"})))),(0,r.kt)("tbody",{parentName:"table"},(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:"center"},"Ausdruck"),(0,r.kt)("td",{parentName:"tr",align:"center"},"Matrix")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_freie_antwort_tupel.png"})),(0,r.kt)("td",{parentName:"tr",align:"center"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_freie_antwort_menge.png"}))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:"center"},"Tupel"),(0,r.kt)("td",{parentName:"tr",align:"center"},"Menge")))),(0,r.kt)("p",null,"In der Box \u201eL\xf6sung\u201c gibt die folgenden Bedienelemente: Radiobuttons, zwei oder mehr Eingabefelder und ein bzw. drei einfache Buttons. Bevor \xc4nderungen vorgenommen worden sind, gibt es nur den einfachen Button ",(0,r.kt)("button",null,"Vorschau"),". Sobald etwas bearbeitet worden ist, erscheinen auch die Buttons ",(0,r.kt)("button",null,"Speichern")," und ",(0,r.kt)("button",null,"Verwerfen"),". Alle m\xf6glichen Bedienelemente werden nun beschrieben. Dabei wird an entsprechender Stelle auf Besonderheiten, die durch die Wahl den Antworttyps begr\xfcndet sind, erl\xe4utert."),(0,r.kt)("table",null,(0,r.kt)("tr",null,(0,r.kt)("td",{valign:"top"},(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/frage_freie_antwort_aenderung.png",width:"3500"}),(0,r.kt)("br",null),(0,r.kt)("br",null),(0,r.kt)("ul",null,(0,r.kt)("li",null,(0,r.kt)("button",null,"Speichern")," Speichere die vorgenommenen \xc4nderungen. Dieser Button wird erst angezeigt, nachdem etwas bearbeitet worden ist."),(0,r.kt)("li",null,(0,r.kt)("button",null,"Verwerfen")," Verwirf die vorgenommenen \xc4nderungen. Dieser Button wird erst angezeigt, nachdem etwas bearbeitet worden ist."),(0,r.kt)("li",null,(0,r.kt)("form",null,"Typ: ",(0,r.kt)("input",{type:"radio",id:"aus",name:"lang",checked:!0}),(0,r.kt)("label",{for:"Aus"}," Ausdruck "),(0,r.kt)("input",{type:"radio",id:"mat",name:"lang"}),(0,r.kt)("label",{for:"mat"}," Matrix"),(0,r.kt)("input",{type:"radio",id:"tup",name:"lang"}),(0,r.kt)("label",{for:"tup"}," Tupel "),(0,r.kt)("input",{type:"radio",id:"men",name:"lang"}),(0,r.kt)("label",{for:"men"}," Menge")),(0,r.kt)("br",null),"Radiobuttons zur Festlegung des Antworttyps. Zur Auswahl stehen ",(0,r.kt)("i",null,"Ausdruck"),", ",(0,r.kt)("i",null,"Matrix"),", ",(0,r.kt)("i",null,"Tupel")," und ",(0,r.kt)("i",null,"Menge"),". Der voreingestellte Wert ist ",(0,r.kt)("i",null,"Ausdruck"),"."))),(0,r.kt)("td",null,(0,r.kt)("ul",null,(0,r.kt)("li",null,(0,r.kt)("form",null,"Anzahl der Zeilen: ",(0,r.kt)("input",{type:"radio",id:"1",name:"lang"}),(0,r.kt)("label",{for:"1"}," 1 "),(0,r.kt)("input",{type:"radio",id:"2",name:"lang",checked:!0}),(0,r.kt)("label",{for:"2"}," 2"),(0,r.kt)("input",{type:"radio",id:"3",name:"lang"}),(0,r.kt)("label",{for:"3"}," 3 "),(0,r.kt)("input",{type:"radio",id:"4",name:"lang"}),(0,r.kt)("label",{for:"4"}," 4")),(0,r.kt)("form",null,"Anzahl der Spalten: ",(0,r.kt)("input",{type:"radio",id:"1a",name:"lang"}),(0,r.kt)("label",{for:"1a"}," 1 "),(0,r.kt)("input",{type:"radio",id:"2a",name:"lang",checked:!0}),(0,r.kt)("label",{for:"2a"}," 2"),(0,r.kt)("input",{type:"radio",id:"3a",name:"lang"}),(0,r.kt)("label",{for:"3a"}," 3 "),(0,r.kt)("input",{type:"radio",id:"4a",name:"lang"}),(0,r.kt)("label",{for:"4a"}," 4")),(0,r.kt)("br",null),"Radiobuttons zur Festlegung der Zeilen- und Spaltenzahl. Diese Einstellungsm\xf6glichkeit ist nur beim L\xf6sungtyp ",(0,r.kt)("i",null,"Matrix")," verf\xfcgbar. Zur Auswahl stehen ",(0,r.kt)("i",null,"1"),", ",(0,r.kt)("i",null,"2"),", ",(0,r.kt)("i",null,"3")," und ",(0,r.kt)("i",null,"4"),". Der voreingestellte Wert ist jeweils ",(0,r.kt)("i",null,"2"),"."),(0,r.kt)("li",null,(0,r.kt)("form",null,(0,r.kt)("p",null,(0,r.kt)("input",{type:"text",id:"fname",name:"fname"}),(0,r.kt)("br",null)))," Eingabefeld f\xfcr die L\xf6sung. Bei Matrizen betr\xe4gt die Anzahl der Eingabefelder  Zeilenzahl * Spaltenzahl. Die Verwendung von $-Zeichen f\xfchrt zu einem Syntaxfehler."),(0,r.kt)("li",null,(0,r.kt)("button",null,"Vorschau")," Zeige eine Vorschau der eingegebenen L\xf6sung an. Durch Bearbeiten der L\xf6sung verschwindet die Vorschau und kann mit diesem Button wieder ge\xf6ffnet werden."),(0,r.kt)("li",null,(0,r.kt)("form",null,(0,r.kt)("p",null,(0,r.kt)("label",{for:"fname"},"Erkl\xe4rung"),(0,r.kt)("br",null),(0,r.kt)("input",{type:"text",id:"fname",name:"fname"}),(0,r.kt)("br",null)))," Eingabefeld f\xfcr den Erkl\xe4rungstext. Um LaTeX zu verwenden, setze den gew\xfcnschten Text zwischen $-Zeichen."))))),(0,r.kt)("h3",{id:"kopie-erstellen"},"Kopie erstellen"),(0,r.kt)("p",null,"Im Dialogfeld \u201eKopie erstellen\u201c kann eine Kopie der Frage erstellt werden. Es \xf6ffnet sich, nachdem in der Box \u201eBasisdaten\u201c auf ",(0,r.kt)("button",null,"Kopie erstellen")," geklickt worden ist."),(0,r.kt)("table",null,(0,r.kt)("tr",null,(0,r.kt)("td",null,(0,r.kt)("img",{src:"https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_kopie_erstellen.png",width:"2800"})),(0,r.kt)("td",null,(0,r.kt)("ul",null,(0,r.kt)("li",null,(0,r.kt)("form",null,(0,r.kt)("input",{type:"checkbox",id:"not",name:"ev"}),(0,r.kt)("label",{for:"not"}," Quiz, in der die Frage vorkommt"),(0,r.kt)("br",null),(0,r.kt)("input",{type:"checkbox",id:"med",name:"ev"}),(0,r.kt)("label",{for:"med"}," Quiz, in der die Frage vorkommt"),(0,r.kt)("br",null),(0,r.kt)("input",{type:"checkbox",id:"eve",name:"ev"}),(0,r.kt)("label",{for:"eve"}," Quiz, in der die Frage vorkommt")),(0,r.kt)("br",null)," Liste aller Quizzes, in denen die Frage vorkommt, mit Checkboxen. Klicke eine Box an, um einen Haken zu setzen bzw. zu entfernen. Nur in den ausgew\xe4hlten Quizzes wird dann die Kopie der Frage verwendet."),(0,r.kt)("li",null,(0,r.kt)("button",null,"Kopie erstellen und bearbeiten")," Erstelle eine Kopie und wechsel auf die Bearbeitungsseite der kopierten Frage."),(0,r.kt)("li",null,(0,r.kt)("button",null,"Abbrechen")," Brich die Aktion ab und schlie\xdfe das Dialogfenster."))))),(0,r.kt)("p",null,"Von dieser Funktion sollte m\xf6glichst NICHT Gebrauch gemacht werden, da Duplikate die Datenbankpflege erschweren. Bei fehlenden Bearbeitungsrechten f\xfcr die Frage, sollte eine Person mit entsprechenden Rechten beim Finden von Fehlern kontaktiert werden."),(0,r.kt)("h2",{id:"verwandte-seite"},"Verwandte Seite"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"edit-medium"},"Medium bearbeiten")),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"edit-quiz"},"Quiz bearbeiten")),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"quiz-editor"},"Quizeditor")),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"edit-remark"},"Quizerl\xe4uterung bearbeiten")),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"edit-medium-remark"},"Quizerl\xe4uterung bearbeiten")," (Medium)"),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"edit-medium-question"},"Quizfrage bearbeiten")," (Medium)"),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"self-assessment"},"Selbsttest"))))}g.isMDXComponent=!0},5604:(e,t,n)=>{n.d(t,{Z:()=>i});const i=n.p+"assets/images/frage_bearbeiten-052333e1a8f5960b7f30594cfb42935d.png"}}]);