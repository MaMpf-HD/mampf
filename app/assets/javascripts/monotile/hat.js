// BSD-3-Clause licensed by Craig S. Kaplan
// adapted from: https://github.com/isohedral/hatviz

// A bit of a "hacky" fix. This is the only way I found that works
// so that the canvas is loaded even if the site is left
// e.g. user clicks on "Register" or changes language from "De" to "En"
// with the button on the landing page.
// Also see the following link for a possible workaround, which does not work
// for us in conjunction with turbolink: 
// https://github.com/processing/p5.js/wiki/p5.js-overview#why-cant-i-assign-variables-using-p5-functions-and-variables-before-setup
$(document).on('turbolinks:load', () => {
	try {
		setup();
	} catch (err) {
		if (err instanceof ReferenceError) {
			console.log('Setup P5.js');
			return;
		}
		console.error(err);
	}
});

const INITIAL_TO_SCREEN = [45, 0, 0, 0, -45, 0];
let to_screen = INITIAL_TO_SCREEN;
let tiles;
let level;
let box_height;

let monotile_btn;
let reset_btn;

const colors = {
	'H1': [0, 137, 212],
	'H': [148, 205, 235],
	'T': [251, 251, 251],
	'P': [250, 250, 250],
	'F': [191, 191, 191]
};
let black = [0, 0, 0];

function drawPolygon(shape, T, f, s, w) {
	if (f != null) {
		fill(f);
	} else {
		noFill();
	}
	if (s != null) {
		stroke(s);
		strokeWeight(w);
	} else {
		noStroke();
	}
	beginShape();
	for (let p of shape) {
		const tp = transPt(T, p);
		vertex(tp.x, tp.y);
	}
	endShape(CLOSE);
}

// The base level of the scene, a single hat tile, including a label
// for colouring
class HatTile {
	constructor(label) {
		this.label = label;
	}

	draw(S, level) {
		drawPolygon(
			hat_outline, S, colors[this.label], black, 1);
	}
}

// A group that collects a list of transformed children and an outline
class MetaTile {
	constructor(shape, width) {
		this.shape = shape;
		this.width = width;
		this.children = [];
	}

	addChild(T, geom) {
		this.children.push({ T: T, geom: geom });
	}

	evalChild(n, i) {
		return transPt(this.children[n].T, this.children[n].geom.shape[i]);
	}

	draw(S, level) {
		if (level > 0) {
			for (let g of this.children) {
				g.geom.draw(mul(S, g.T), level - 1);
			}
		} else {
			drawPolygon(this.shape, S, null, black, this.width);
		}
	}

	recentre() {
		let cx = 0;
		let cy = 0;
		for (let p of this.shape) {
			cx += p.x;
			cy += p.y;
		}
		cx /= this.shape.length;
		cy /= this.shape.length;
		const tr = pt(-cx, -cy);

		for (let idx = 0; idx < this.shape.length; ++idx) {
			this.shape[idx] = padd(this.shape[idx], tr);
		}

		const M = ttrans(-cx, -cy);
		for (let ch of this.children) {
			ch.T = mul(M, ch.T);
		}
	}
}

const H1_hat = new HatTile('H1');
const H_hat = new HatTile('H');
const T_hat = new HatTile('T');
const P_hat = new HatTile('P');
const F_hat = new HatTile('F');

function initH() {
	const H_outline = [
		pt(0, 0), pt(4, 0), pt(4.5, hr3),
		pt(2.5, 5 * hr3), pt(1.5, 5 * hr3), pt(-0.5, hr3)];
	const meta = new MetaTile(H_outline, 2);

	meta.addChild(
		matchTwo(
			hat_outline[5], hat_outline[7], H_outline[5], H_outline[0]),
		H_hat);
	meta.addChild(
		matchTwo(
			hat_outline[9], hat_outline[11], H_outline[1], H_outline[2]),
		H_hat);
	meta.addChild(
		matchTwo(
			hat_outline[5], hat_outline[7], H_outline[3], H_outline[4]),
		H_hat);
	meta.addChild(
		mul(ttrans(2.5, hr3),
			mul(
				[-0.5, -hr3, 0, hr3, -0.5, 0],
				[0.5, 0, 0, 0, -0.5, 0])),
		H1_hat);

	return meta;
}

function initT() {
	const T_outline = [
		pt(0, 0), pt(3, 0), pt(1.5, 3 * hr3)];
	const meta = new MetaTile(T_outline, 2);

	meta.addChild(
		[0.5, 0, 0.5, 0, 0.5, hr3],
		T_hat);

	return meta;
}

function initP() {
	const P_outline = [
		pt(0, 0), pt(4, 0),
		pt(3, 2 * hr3),
		pt(-1, 2 * hr3)
	];
	const meta = new MetaTile(P_outline, 2);

	meta.addChild([0.5, 0, 1.5, 0, 0.5, hr3], P_hat);
	meta.addChild(
		mul(ttrans(0, 2 * hr3),
			mul([0.5, hr3, 0, -hr3, 0.5, 0],
				[0.5, 0.0, 0.0, 0.0, 0.5, 0.0])),
		P_hat);

	return meta;
}

function initF() {
	const F_outline = [
		pt(0, 0), pt(3, 0),
		pt(3.5, hr3), pt(3, 2 * hr3), pt(-1, 2 * hr3)
	];
	const meta = new MetaTile(F_outline, 2);

	meta.addChild(
		[0.5, 0, 1.5, 0, 0.5, hr3],
		F_hat);
	meta.addChild(
		mul(ttrans(0, 2 * hr3),
			mul([0.5, hr3, 0, -hr3, 0.5, 0],
				[0.5, 0.0, 0.0, 0.0, 0.5, 0.0])),
		F_hat);

	return meta;
}

function constructPatch(H, T, P, F) {
	const rules = [
		['H'],
		[0, 0, 'P', 2],
		[1, 0, 'H', 2],
		[2, 0, 'P', 2],
		[3, 0, 'H', 2],
		[4, 4, 'P', 2],
		[0, 4, 'F', 3],
		[2, 4, 'F', 3],
		[4, 1, 3, 2, 'F', 0],
		[8, 3, 'H', 0],
		[9, 2, 'P', 0],
		[10, 2, 'H', 0],
		[11, 4, 'P', 2],
		[12, 0, 'H', 2],
		[13, 0, 'F', 3],
		[14, 2, 'F', 1],
		[15, 3, 'H', 4],
		[8, 2, 'F', 1],
		[17, 3, 'H', 0],
		[18, 2, 'P', 0],
		[19, 2, 'H', 2],
		[20, 4, 'F', 3],
		[20, 0, 'P', 2],
		[22, 0, 'H', 2],
		[23, 4, 'F', 3],
		[23, 0, 'F', 3],
		[16, 0, 'P', 2],
		[9, 4, 0, 2, 'T', 2],
		[4, 0, 'F', 3]
	];

	ret = new MetaTile([], H.width);
	shapes = { 'H': H, 'T': T, 'P': P, 'F': F };

	for (let r of rules) {
		if (r.length == 1) {
			ret.addChild(ident, shapes[r[0]]);
		} else if (r.length == 4) {
			const poly = ret.children[r[0]].geom.shape;
			const T = ret.children[r[0]].T;
			const P = transPt(T, poly[(r[1] + 1) % poly.length]);
			const Q = transPt(T, poly[r[1]]);
			const nshp = shapes[r[2]];
			const npoly = nshp.shape;

			ret.addChild(
				matchTwo(npoly[r[3]], npoly[(r[3] + 1) % npoly.length], P, Q),
				nshp);
		} else {
			const chP = ret.children[r[0]];
			const chQ = ret.children[r[2]];

			const P = transPt(chQ.T, chQ.geom.shape[r[3]]);
			const Q = transPt(chP.T, chP.geom.shape[r[1]]);
			const nshp = shapes[r[4]];
			const npoly = nshp.shape;

			ret.addChild(
				matchTwo(npoly[r[5]], npoly[(r[5] + 1) % npoly.length], P, Q),
				nshp);
		}
	}

	return ret;
}

// You can read the paper preprint if you'd like to know how this works:
// https://arxiv.org/abs/2303.10798
function constructMetatiles(patch) {
	const bps1 = patch.evalChild(8, 2);
	const bps2 = patch.evalChild(21, 2);
	const rbps = transPt(rotAbout(bps1, -2.0 * PI / 3.0), bps2);

	const p72 = patch.evalChild(7, 2);
	const p252 = patch.evalChild(25, 2);

	const llc = intersect(bps1, rbps,
		patch.evalChild(6, 2), p72);
	let w = psub(patch.evalChild(6, 2), llc);

	const new_H_outline = [llc, bps1];
	w = transPt(trot(-PI / 3), w);
	new_H_outline.push(padd(new_H_outline[1], w));
	new_H_outline.push(patch.evalChild(14, 2));
	w = transPt(trot(-PI / 3), w);
	new_H_outline.push(psub(new_H_outline[3], w));
	new_H_outline.push(patch.evalChild(6, 2));

	const new_H = new MetaTile(new_H_outline, patch.width * 2);
	for (let ch of [0, 9, 16, 27, 26, 6, 1, 8, 10, 15]) {
		new_H.addChild(patch.children[ch].T, patch.children[ch].geom);
	}

	const new_P_outline = [p72, padd(p72, psub(bps1, llc)), bps1, llc];
	const new_P = new MetaTile(new_P_outline, patch.width * 2);
	for (let ch of [7, 2, 3, 4, 28]) {
		new_P.addChild(patch.children[ch].T, patch.children[ch].geom);
	}

	const new_F_outline = [
		bps2, patch.evalChild(24, 2), patch.evalChild(25, 0),
		p252, padd(p252, psub(llc, bps1))];
	const new_F = new MetaTile(new_F_outline, patch.width * 2);
	for (let ch of [21, 20, 22, 23, 24, 25]) {
		new_F.addChild(patch.children[ch].T, patch.children[ch].geom);
	}

	const AAA = new_H_outline[2];
	const BBB = padd(new_H_outline[1],
		psub(new_H_outline[4], new_H_outline[5]));
	const CCC = transPt(rotAbout(BBB, -PI / 3), AAA);
	const new_T_outline = [BBB, CCC, AAA];
	const new_T = new MetaTile(new_T_outline, patch.width * 2);
	new_T.addChild(patch.children[11].T, patch.children[11].geom);

	new_H.recentre();
	new_P.recentre();
	new_F.recentre();
	new_T.recentre();

	return [new_H, new_T, new_P, new_F]
}

function isButtonActive(but) {
	return but.elt.style.border.length > 0;
}

function setButtonActive(but, b) {
	but.elt.style.border = (b ? "3px solid black" : "");
}

function addButton(name, f) {
	const ret = createButton(name);
	ret.position(10, box_height);
	ret.size(125, 25);
	ret.mousePressed(f);
	box_height += 40;

	return ret;
}

function setup() {
	box_height = 10;

	let canvas = createCanvas(windowWidth, windowHeight);
	canvas.id('einstein-monotile-canvas');
	canvas.parent('einstein-monotile');

	tiles = [initH(), initT(), initP(), initF()];
	level = 1;

	// Reset button
	reset_btn = addButton("Reset", () => reset());
	reset_btn.class('btn btn-light monotile-btn');

	// Monotile button
	monotile_btn = addButton("Monotile", () => monotile());
	monotile_btn.class('btn btn-light monotile-btn disabled');

	// Find out more button
	info_btn = addButton("Info", () => {
		window.open('https://cs.uwaterloo.ca/~csk/hat/', '_blank');
	});
	info_btn.class('btn btn-light monotile-btn');

	// Little animation at the beginning
	monotile();
	monotile();
	monotile();
}

function reset() {
	tiles = [initH(), initT(), initP(), initF()];
	level = 1;
	to_screen = INITIAL_TO_SCREEN;
	monotile();
	monotile_btn.removeClass('disabled');
	loop();
}

function monotile() {
	// Don't go past a certain level to avoid using too much memory
	// and therefore crashing the browser.
	if (level == 5) {
		monotile_btn.addClass('disabled');
		return;
	}

	const patch = constructPatch(...tiles);
	tiles = constructMetatiles(patch);
	level++;
	loop();
}

function draw() {
	background(255); // white background
	push();
	translate(width / 2, height / 2);
	tiles[0].draw(to_screen, level);
	pop();

	// Draw black overlay
	fill(0, 0, 0, 70);
	noStroke();
	rect(0, 0, windowWidth, windowHeight);

	noLoop();
}

function windowResized() {
	resizeCanvas(windowWidth, windowHeight);
}


/* Mouse movement */
let dragging = false;
DELTA_THRESHOLD = 5;

function mousePressed() {
	dragging = true;
	loop();
}

function mouseDragged(event) {
	if (!dragging) {
		return true;
	}

	// Only move if the mouse has moved a certain amount
	const diffX = mouseX - pmouseX;
	const diffY = mouseY - pmouseY;
	if (diffX <= DELTA_THRESHOLD && diffY == DELTA_THRESHOLD) {
		return true;
	}

	// Recalculate the transformation matrix
	to_screen = mul(ttrans(diffX, diffY), to_screen);

	loop();
	return false;
}

$(document).ready(function () {
	// Prevent mousemove on divs to propagate to canvas
	$('#signin-box').on('mousemove', (event) => {
		event.stopPropagation();
	});
	$('#footer-bar').on('mousemove', (event) => {
		event.stopPropagation();
	});
	$('#announcement-box').on('mousemove', (event) => {
		event.stopPropagation();
	});
});
