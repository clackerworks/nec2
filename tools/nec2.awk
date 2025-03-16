BEGIN {}
END {}

NF == 0 {next}
/^#/ {next}
/^cm/ || /^ce/ || /^CM/ || /^CE/ {print; next}
{ gsub("\;", " "); 
	gsub("\{", " "); 
	gsub("\}", " "); print }
