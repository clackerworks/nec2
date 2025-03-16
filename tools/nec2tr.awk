# NEC2 Output post-processor
BEGIN {}
END {}
{lineno++}

# NEC2 Post Processor language
/.necstart/ {
	print ".PS";
	innecpp = 1;
	next;
}

/.necend/ {
	print ".PE";
	innecpp = 0;
	next;
}

innecpp == 0 {print; next}
/^#/{print; next}

$1 == "pic"	{ shiftfields(1); print; next }	# pic pass-thru
$1 == "rp" { shiftfields(1); rp_cmd(); next}
$1 == "necdataf" {shiftfields(1); load_outfile(); next}

function rp_cmd() {
	# generate report
	rp_init();
	if($1 == "horizontal") {
		polar_horizontal();
		if($2 == "etheta") {
			if($3 == "max") {
				hrp_etheta(e_theta_max_theta);
			} else hrp_etheta($3);
		}
		if($2 == "ephi") {
			if($3 == "max") {
				hrp_ephi(e_phi_max_theta);
			} else hrp_ephi($3);
		}
	}
	if($1 == "vertical") {
		polar_vertical();
		if($2 == "etheta") {
			if($3 == "max") {
				vrp_etheta(e_theta_max_phi);
			} else vrp_etheta($3);
		}
		if($2 == "ephi") {
			if($3 == "max") {
				vrp_ephi(e_phi_max_phi);
			} else vrp_ephi($3);
		}
	}
}

function load_outfile() {
	rp_head = 0;
	line = 0;
	inrptable = 0;
	rp_line = 0;
	while((getline necdata < $1 ) >0) {
		line++;
		if(match(necdata, /- - - RADIATION PATTERNS - - -/)) {
			rp_head = line;
			inrptable = 1;
		}
		#print rp_head*1 line necdata;
		if(line > (rp_head + 7) && inrptable == 1) {
			#print necdata;
 			nf = split(necdata, rp_fields);
			#if(nf == 0 && line > rp_head + 7) inrptable == 0;
			if(nf == 12 && inrptable == 1) {
				rp_line++;
				theta[rp_line] = rp_fields[1] * 1.0;
				phi[rp_line] = rp_fields[2] * 1.0;
				g_vdb[rp_line] = rp_fields[3] * 1.0;
				g_hdb[rp_line] = rp_fields[4] * 1.0;
				g_totaldb[rp_line] = rp_fields[5] * 1.0;
				pol_axialration[rp_line] = rp_fields[6] * 1.0;
				pol_tilt[rp_line] = rp_fields[7] * 1.0;
				pol_sense[rp_line] = rp_fields[8];
				e_theta[rp_line] = rp_fields[9] * 1.0;
				e_theta_phase[rp_line] = rp_fields[10] * 1.0;
				e_phi[rp_line] = rp_fields[11] * 1.0;
				e_phi_phase[rp_line] = rp_fields[12] * 1.0;
			}
		}
	}
	close($1);
}

# NEC2 Post Processor language

# Useful functions
function abs(a) {
	if(a >= 0) return a;
	else return 0 - a;
}

function deg2rad (deg) {
	rad = deg * pi / 180;
	return rad;
}

function pol2xy (h,deg) {
	xy[1] = h * cos(deg2rad(deg));
	xy[2] = h * sin(deg2rad(deg));
	return xy;
}

function shiftfields(n, i) {	# move $n+1..$NF to $n..$NF-1, zap $NF
	for (i = n; i < NF; i++)
		$i = $(i+1)
	$NF = ""
	NF--
}




function angulargrid (deg, incircle, outcircle) {
	j = deg;
	printf("x1 = %s.rad * cos(%f * pi / 180)\n", incircle, j);
	printf("y1 = %s.rad * sin(%f * pi / 180)\n", incircle, j);
	printf("x2 = %s.rad * cos(%f * pi / 180)\n", outcircle, j);
	printf("y2 = %s.rad * sin(%f * pi / 180)\n", outcircle, j);
	print "line from RP.c + (x1,y1) to RP.c + (x2,y2)";
	printf("x1 = %s.rad * cos(%f * pi / 180)\n", incircle, j + 180);
	printf("y1 = %s.rad * sin(%f * pi / 180)\n", incircle, j + 180);
	printf("x2 = %s.rad * cos(%f * pi / 180)\n", outcircle, j + 180);
	printf("y2 = %s.rad * sin(%f * pi / 180)\n", outcircle, j + 180);
	print "line from RP.c + (x1,y1) to RP.c + (x2,y2)";
}

function label (deg, rad, value) {
	j = deg;
	printf("x1 = %f * cos(%f * pi / 180)\n", rad, j);
	printf("y1 = %f * sin(%f * pi / 180)\n", rad, j);
	printf("\"\\s-1\\f(HB%s\\fP\\s+1\" at RP.c + (x1,y1)\n", value);
}

function vector(deg, rad) {
	j = deg;
	printf("x1 = vecrad * cos(vecdeg * pi / 180)\n");
	printf("y1 = vecrad * sin(vecdeg * pi / 180)\n");
	printf("x2 = %f * cos(%f * pi / 180)\n", rad, j);
	printf("y2 = %f * sin(%f * pi / 180)\n", rad, j);
	print "line from RP.c + (x1,y1) to RP.c + (x2,y2)";
 	move(deg, rad);
}

function move(deg,rad) {
	printf("vecdeg = %f\n", deg);
	printf("vecrad = %f\n", rad);
}

function rp_stats() {
	for(i = 0; i < rp_line; i++) {
			p = abs(e_theta[i]);
			if(e_theta_max < p) {
				e_theta_max = p;
				e_theta_max_theta = theta[i];
 				e_theta_max_phi = phi[i];
			}
 	}
 	for(i = 0; i < rp_line; i++) {
			p = abs(e_phi[i]);
			if(e_phi_max < p) {
				e_phi_max = p;
				e_phi_max_theta = theta[i];
 				e_phi_max_phi = phi[i];
			}
 	}
}


function hrp_ephi(ref) {
	print "# horizontal phi"
	move(0,0);
 	if(e_phi_max == 0){ return;}
 	scale = plotsize / 2 / e_phi_max;	
 	for(i = 0; i < rp_line; i++){
 		if(theta[i] == ref) {
			vector(phi[i], e_phi[i] * scale);
		}
	}
}

function vrp_ephi(ref) {
	print "# vertical phi"
	move(0,0);
 	if(e_phi_max == 0){ return;}
 	scale = plotsize / 2 / e_phi_max;	
 	for(i = 0; i < rp_line; i++){
 		if(phi[i] == ref) {
			vector(theta[i] + 90, e_phi[i] * scale);
		}
	}
}

function hrp_etheta(ref) {
	print "# horizontal etheta"
	move(0,0);
 	if(e_theta_max == 0){ return;}
 	scale = plotsize / 2 / e_theta_max;	
 	for(i = 0; i < rp_line; i++){
 		if(theta[i] == ref) {
			vector(phi[i], e_theta[i] * scale);
		}
	}
}

function vrp_etheta(ref) {
	print "# vertical etheta"
	move(0,0);
 	if(e_theta_max == 0){ return;}
 	scale = plotsize / 2 / e_theta_max;	
 	for(i = 0; i < rp_line; i++){
 		if(phi[i] == ref) {
			vector(theta[i] + 90, e_theta[i] * scale);
		}
	}
}
	
function polar_horizontal() {
	print "vecrad = 0.0"
	print "vecdeg = 0.0"
	# show linear polar grid
	labelloc = plotsize /2 + 0.25;
	printf("RP: box invis wid %f ht %f\n", plotsize, plotsize);
	print "pi = 3.14159265"
	for(i = 1; i <= ngrid; i++) {
		printf("C%i: circle rad %f dotted with .c at RP.c\n", 
								i, (i * plotsize/ngrid)/2);
	}
	printf("Clast: C%i\n",ngrid);
	print "line from RP.n to RP.s"; label(0, labelloc, "0°x");
	print "line from RP.e to RP.w"
	angulargrid(15, "C2", "Clast"); 
	angulargrid(30, "C1", "Clast"); label(30, labelloc, "30°");
	angulargrid(45, "C2", "Clast");
	angulargrid(60, "C1", "Clast"); label(60, labelloc, "60°");
	angulargrid(75, "C2", "Clast");
	angulargrid(90, "C1", "Clast"); label(90, labelloc, "90°y");
	angulargrid(105, "C2", "Clast");
	angulargrid(120, "C1", "Clast");label(120, labelloc, "120°");
	angulargrid(135, "C2", "Clast"); 
	angulargrid(150, "C1", "Clast");label(150, labelloc, "150°");
	angulargrid(165, "C2", "Clast");
	label(180, labelloc, "180°");
	label(210, labelloc, "210°");
	label(240, labelloc, "240°");
	label(270, labelloc, "270°");
	label(300, labelloc, "300°");
	label(330, labelloc, "330°");
	#
}

function polar_vertical() {
	print "vecrad = 0.0"
	print "vecdeg = 0.0"
	# show linear polar grid
	labelloc = plotsize /2 + 0.25;
	printf("RP: box invis wid %f ht %f\n", plotsize, plotsize);
	print "pi = 3.14159265"
	for(i = 1; i <= ngrid; i++) {
		printf("C%i: circle rad %f dotted with .c at RP.c\n", 
								i, (i * plotsize/ngrid)/2);
	}
	printf("Clast: C%i\n",ngrid);
	print "line from RP.n to RP.s"; label(0, labelloc, "90°xy");
	print "line from RP.e to RP.w"
	angulargrid(15, "C2", "Clast"); 
	angulargrid(30, "C1", "Clast"); label(30, labelloc, "60°");
	angulargrid(45, "C2", "Clast");
	angulargrid(60, "C1", "Clast"); label(60, labelloc, "30°");
	angulargrid(75, "C2", "Clast");
	angulargrid(90, "C1", "Clast"); label(90, labelloc, "0°z");
	angulargrid(105, "C2", "Clast");
	angulargrid(120, "C1", "Clast");label(120, labelloc, "-30°");
	angulargrid(135, "C2", "Clast"); 
	angulargrid(150, "C1", "Clast");label(150, labelloc, "-60°");
	angulargrid(165, "C2", "Clast");
	label(180, labelloc, "-90°");
	label(210, labelloc, "-120°");
	label(240, labelloc, "-150°");
	label(270, labelloc, "-180°");
	label(300, labelloc, "150°");
	label(330, labelloc, "120°");
	# end polar grid
}

function hplot_max_ephi() {
	grid_type1()
	hrp_phi(e_phi_max_theta)
}

function vplot_max_ephi() {
	grid_type2()
	vrp_phi(e_phi_max_phi);
}

function vplot_max_etheta() {
	grid_type2()
	vrp_etheta(e_theta_max_phi);
}

function hplot_max_etheta() {
	grid_type1()
	hrp_etheta(e_theta_max_theta)
}

function rp_init() {
	plotsize = 4;
	ngrid = 8;
	e_theta_max = 0;
	e_phi_max = 0;
	e_theta_max_theta = 0;
	e_phi_max_theta = 0;
	e_theta_max_phi = 0;
	e_phi_max_phi = 0;
	rp_stats();
}
