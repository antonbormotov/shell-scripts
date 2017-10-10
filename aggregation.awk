BEGIN {
        FS="[[]{1}| |-|:"
}
{
	dh_count[0$2][0$5]++
}
END {
	for (i in dh_count) {
		
		l1=1

		for (l2 in dh_count[i])
			indices[++l1] = l2
		n = asort(indices)
		
		tmp = 0
		counter = 0
		print "Day " i

		for (l1 = 1; l1 <= n; l1++) {

			tmp += dh_count[i][indices[l1]]
			counter++
			print "\th " indices[l1] " = " dh_count[i][indices[l1]]
		}
		print "\t Avg/h ~= " tmp / counter
		delete indices
	}
}
