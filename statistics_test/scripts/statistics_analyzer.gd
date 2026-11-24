extends RefCounted
## Pure statistical calculations for the Statistics Test tool.
##
## Deliberately self-contained: no game systems, no autoloads, no class_name
## registration. All functions are static, so the script can be preloaded and
## called directly.
##
## Main entry point: welch_two_sample_t_test() implements a Welch two-sample
## t-test directly in GDScript. The two-sided p-value is computed from the
## t-distribution through the regularized incomplete beta function (continued
## fraction, Numerical Recipes style), because Godot has no built-in for it.
##
## Sign convention (required by the tool):
##   t = (mean_current - mean_reference) / se
##   positive t -> current sample mean ABOVE reference mean
##   negative t -> current sample mean BELOW reference mean

const _LN_2PI := 1.8378770664093453
const _LANCZOS_G7: Array[float] = [
	0.99999999999980993, 676.5203681218851, -1259.1392167224028,
	771.32342877765313, -176.61502916214059, 12.507343278686905,
	-0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7,
]


## Arithmetic mean. Returns NAN for an empty array.
static func mean(values) -> float:
	if values.is_empty():
		return NAN
	var total := 0.0
	for v in values:
		total += float(v)
	return total / values.size()


## Unbiased (n - 1) sample variance. Returns 0.0 for fewer than 2 values.
static func sample_variance(values) -> float:
	var n: int = values.size()
	if n < 2:
		return 0.0
	var m := mean(values)
	var acc := 0.0
	for v in values:
		var d := float(v) - m
		acc += d * d
	return acc / (n - 1)


static func sample_std_dev(values) -> float:
	return sqrt(sample_variance(values))


## Welch (unequal-variance) two-sample t-test comparing a fixed reference
## sample against a current sample. Returns a Dictionary with keys:
##   valid, note, t, df, p_two_tailed,
##   mean_reference, mean_current, mean_diff (current - reference),
##   var_reference, var_current, se, n_reference, n_current
static func welch_two_sample_t_test(reference_sample, current_sample) -> Dictionary:
	var n_reference: int = reference_sample.size()
	var n_current: int = current_sample.size()
	var result := {
		"valid": false, "note": "", "t": NAN, "df": NAN, "p_two_tailed": NAN,
		"mean_reference": NAN, "mean_current": NAN, "mean_diff": NAN,
		"var_reference": NAN, "var_current": NAN, "se": NAN,
		"n_reference": n_reference, "n_current": n_current,
	}
	if n_reference < 2 or n_current < 2:
		result["note"] = "Both samples need at least 2 values each."
		return result

	var mean_reference := mean(reference_sample)
	var mean_current := mean(current_sample)
	var var_reference := sample_variance(reference_sample)
	var var_current := sample_variance(current_sample)
	var se_sq := var_reference / n_reference + var_current / n_current

	result["mean_reference"] = mean_reference
	result["mean_current"] = mean_current
	result["mean_diff"] = mean_current - mean_reference
	result["var_reference"] = var_reference
	result["var_current"] = var_current

	if se_sq <= 0.0:
		# Degenerate case: both samples are constant.
		result["valid"] = true
		result["df"] = INF
		result["se"] = 0.0
		if is_equal_approx(mean_reference, mean_current):
			result["t"] = 0.0
			result["p_two_tailed"] = 1.0
			result["note"] = "Both samples are constant with equal means."
		else:
			result["t"] = INF if mean_current > mean_reference else -INF
			result["p_two_tailed"] = 0.0
			result["note"] = "Both samples are constant with different means."
		return result

	var se := sqrt(se_sq)
	var t := (mean_current - mean_reference) / se
	var df_den := pow(var_reference / n_reference, 2.0) / (n_reference - 1) \
			+ pow(var_current / n_current, 2.0) / (n_current - 1)
	var df := se_sq * se_sq / df_den if df_den > 0.0 else INF

	result["valid"] = true
	result["t"] = t
	result["df"] = df
	result["se"] = se
	result["p_two_tailed"] = two_tailed_p_value(t, df)
	return result


## Two-sided p-value P(|T| >= |t|) for Student's t-distribution with df
## degrees of freedom, via the regularized incomplete beta function.
static func two_tailed_p_value(t: float, df: float) -> float:
	if is_nan(t) or is_nan(df) or df <= 0.0:
		return NAN
	var at := absf(t)
	if at == 0.0:
		return 1.0
	if is_inf(at):
		return 0.0
	var x := df / (df + at * at)
	return clampf(_regularized_incomplete_beta(df * 0.5, 0.5, x), 0.0, 1.0)


## Frequency of each integer value in [min_value, max_value].
## Non-integer inputs are binned at their nearest integer; values outside the
## range are ignored (the tool widens the axis so this should not happen).
## Index 0 corresponds to min_value.
static func frequency_counts(values, min_value: int, max_value: int) -> PackedInt64Array:
	var counts := PackedInt64Array()
	counts.resize(maxi(0, max_value - min_value + 1))
	for v in values:
		var bin := int(roundf(float(v)))
		if bin < min_value or bin > max_value:
			continue
		counts[bin - min_value] += 1
	return counts


## Random integer in [min_value, max_value] whose weights decay linearly
## around `center`: weight(v) = max(0, spread - |v - center|). The
## distribution's mean is exactly `center` for a range symmetric around it,
## so sample means land close to the chosen number. spread <= 0 always
## returns the range-clamped center; larger spreads flatten toward a
## triangular profile across the whole range. Uses the global RNG.
static func random_weighted_int(min_value: int, max_value: int, center: int, spread: float) -> int:
	var lo := mini(min_value, max_value)
	var hi := maxi(min_value, max_value)
	var total := 0.0
	for v in range(lo, hi + 1):
		total += _random_weight(v, center, spread)
	if total <= 0.0:
		return clampi(center, lo, hi)
	var roll := randf() * total
	var acc := 0.0
	for v in range(lo, hi + 1):
		acc += _random_weight(v, center, spread)
		if roll <= acc:
			return v
	return hi


static func _random_weight(value: int, center: int, spread: float) -> float:
	if spread <= 0.0:
		return 1.0 if value == center else 0.0
	return maxf(0.0, spread - absf(float(value - center)))


static func _regularized_incomplete_beta(a: float, b: float, x: float) -> float:
	if x <= 0.0:
		return 0.0
	if x >= 1.0:
		return 1.0
	var ln_front := _ln_gamma(a + b) - _ln_gamma(a) - _ln_gamma(b) \
			+ a * log(x) + b * log(1.0 - x)
	var front := exp(ln_front)
	if x < (a + 1.0) / (a + b + 2.0):
		return front * _beta_cont_frac(a, b, x) / a
	return 1.0 - front * _beta_cont_frac(b, a, 1.0 - x) / b


## Log-gamma via the Lanczos approximation (g = 7, 9 coefficients).
static func _ln_gamma(z: float) -> float:
	if z < 0.5:
		return log(PI / sin(PI * z)) - _ln_gamma(1.0 - z)
	z -= 1.0
	var x := _LANCZOS_G7[0]
	for i in range(1, 9):
		x += _LANCZOS_G7[i] / (z + i)
	var t := z + 7.5
	return 0.5 * _LN_2PI + (z + 0.5) * log(t) - t + log(x)


## Continued fraction for the incomplete beta function (Lentz's method).
static func _beta_cont_frac(a: float, b: float, x: float) -> float:
	var max_it := 200
	var eps := 3e-15
	var fpmin := 1e-300
	var qab := a + b
	var qap := a + 1.0
	var qam := a - 1.0
	var c := 1.0
	var d := 1.0 - qab * x / qap
	if absf(d) < fpmin:
		d = fpmin
	d = 1.0 / d
	var h := d
	for m in range(1, max_it + 1):
		var m2 := 2 * m
		var aa := m * (b - m) * x / ((qam + m2) * (a + m2))
		d = 1.0 + aa * d
		if absf(d) < fpmin:
			d = fpmin
		c = 1.0 + aa / c
		if absf(c) < fpmin:
			c = fpmin
		d = 1.0 / d
		h *= d * c
		aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
		d = 1.0 + aa * d
		if absf(d) < fpmin:
			d = fpmin
		c = 1.0 + aa / c
		if absf(c) < fpmin:
			c = fpmin
		d = 1.0 / d
		var delta := d * c
		h *= delta
		if absf(delta - 1.0) < eps:
			break
	return h
