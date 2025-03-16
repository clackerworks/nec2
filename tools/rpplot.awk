# Radation Pattern plot post-processor
BEGIN {
	options = ARGV[2]; ARGV[2] = ""; 
	angle_ref = ARGV[3] * 1.0;  ARGV[3] = ""; 
	header_start_line = 0;
	data_start_line = 0;
	pi = 3.14159265;
	graph_area = 1.5;
	graph_size = graph_area * 0.9;
	textx = graph_size;
	texty = graph_size;
}

END {
	
	if(options == "-vet"){
		rp_vplot(e_theta, angle_ref, "E(theta)", "red");
	}
	if(options == "-vep"){ 
		rp_vplot(e_phi, angle_ref, "E(phi)", "blue");
	}
	if(options == "-het"){
		rp_hplot(e_theta, angle_ref, "E(theta)", "red");
	}
	if(options == "-hep"){ 
		rp_hplot(e_phi, angle_ref, "E(phi)", "blue");
	}
 	print "pe solid"; print "cl";
}
	
{lineno++}

function abs(a) {
	if(a >= 0) return a;
	else return 0 - a;
}

function textxy() {
	texty = texty - 0.1;
	printf("m %g %g\n",textx, texty);
}

# Starting Points 
/- - - RADIATION PATTERNS - - -/ {header_start_line = lineno; dump_start = 1;
	data_start_line = header_start_line + 7;}
NF == 0 && lineno > data_start_line {dump_start = 0}


lineno > data_start_line && dump_start == 1 && NF == 12 {
	data_line++ 
	theta[data_line] = $1 * 1.0;
	phi[data_line] = $2 * 1.0;
	g_vdb[data_line] = $3 * 1.0;
	g_hdb[data_line] = $4 * 1.0;
	g_totaldb[data_line] = $5 * 1.0;
	pol_axialration[data_line] = $6 * 1.0;
	pol_tilt[data_line] = $7 * 1.0;
	pol_sense[data_line] = $8;
	e_theta[data_line] = $9 * 1.0;
	e_theta_phase[data_line] = $10 * 1.0;
	e_phi[data_line] = $11 * 1.0;
	e_phi_phase[data_line] = $12 * 1.0;
}

function report(label, a, a2, a3, maxa, r, or) {
	textxy(); printf("t   Report\n");
	textxy(); printf("t -----------------------------\n");
	textxy(); printf("t orientation = %s\n", or);
	textxy(); printf("t field = %s\n", label);
	textxy(); printf("t %s = %f°\n", a, r);
	textxy(); printf("t max @ theta = %f°\n", a3);
	textxy(); printf("t max @ phi = %f°\n", maxa);
   	textxy(); printf("t scale = %g mV/m\n", (p_max * (1 + 1 - s_factor) * 1000) / 3);
}

function rp_hplot(field, ref, label, color) {
	rp_plot(field, phi, theta, ref, 0, color);
 	printf("m 0 %g\n", graph_size + 0.1);
 	printf("t 90°[y]\n");
 	printf("m %g 0\n", graph_size + 0.05);
 	printf("t [x] 0°\n");
 	report(label, "theta", "phi", max_field_theta, max_field_phi, ref, "horizontal");
}

function rp_vplot(field, ref, label, color) {
	rp_plot(field, theta, phi, ref, 90, color);
 	printf("m 0 %g\n", graph_size + 0.1);
 	printf("t 0°[z]\n");
 	printf("m %g 0\n", graph_size + 0.05);
 	printf("t 90°[xy]\n");
 	report(label, "phi", "theta",  max_field_theta, max_field_phi, ref, "vertical");
}


function rp_plot(magnitude, angle, angle2, ref, offset,  color) {
	drawcount = 0;
	s_factor = 1.0;
	# initialize plot
	print "o";
	printf("ra -%g -%g %g %g\n", graph_area, graph_area, graph_area, graph_area);
	print "e";
	# create polar grid
	print "co 0xFFFFFFFF";
	print "pe dott";
	for(i = 0; i <= 3; i++) printf("ci 0 0 %g\n", i * graph_size / 3);
	xgrid = graph_size * cos(45 * pi / 180);
	ygrid = graph_size * cos(45 * pi / 180);
	printf("li -%g 0  %g 0\n", graph_size, graph_size);
	printf("li 0 -%g 0 %g\n", graph_size, graph_size);
	printf("li -%g -%g %g %g\n", xgrid, ygrid, xgrid, ygrid);
	printf("li %g -%g -%g %g\n", xgrid, ygrid, xgrid, ygrid);
	printf("co %s\n", color); 
	for(i = 0; i < data_line; i++){
		if(angle2[i] == ref){
			p = abs(magnitude[i]);
			if(p_max < p) {p_max = p;}
		}
		d = abs(magnitude[i]);
		if(d_max < d){
			d_max = d;
			max_field_theta = theta[i];
			max_field_phi = phi[i];
		}
 	}
 	if(p_max == 0){ return;}
 	scale = graph_size * s_factor / p_max;	
 	for(i = 0; i < data_line; i++){
 		if(angle2[i] == ref){
 			drawcount++
			x = (magnitude[i]) * scale * cos((offset - angle[i]) * pi / 180);
			y = (magnitude[i]) * scale * sin((offset - angle[i]) * pi / 180);
			if(drawcount < 3) printf("m %g %g \n", x, y);
			else printf("v %g %g \n", x, y);
		}
	}
	print "co kblack";
} 
