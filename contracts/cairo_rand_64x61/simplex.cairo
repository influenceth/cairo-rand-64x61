from starkware.cairo.common.math import signed_div_rem, abs_value
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_label_location

from cairo_math_64x61.math64x61 import Math64x61
from cairo_math_64x61.vec64x61 import Vec64x61

namespace Simplex {
  // Primary method to calculate Simplex 3D noise at a 3D point
  // @param v {fixed[]} A 3d point
  // @return {fixed} A noise value between -1 and 1
  func noise3{range_check_ptr}(v: (felt, felt, felt)) -> felt {
    alloc_locals;

    local C: (felt, felt) = (384307168202282325, 768614336404564650);  // 1/6, 1/3
    local D: (felt, felt, felt, felt) = (
      0,
      1152921504606846976,
      1729382256910270464,
      Math64x61.ONE
    );  // 0, 0.5, 0.75, 1.0

    // First corner
    let v_c_dot = Math64x61.mul(v[0] + v[1] + v[2], C[1]);
    local v_v_c_dot: (felt, felt, felt) = (v[0] + v_c_dot, v[1] + v_c_dot, v[2] + v_c_dot);
    let i = _floor_v3(v_v_c_dot);
    let v_sub_i = Vec64x61.sub(v, i);
    let i_dot_c = Vec64x61.dot(i, (C[0], C[0], C[0]));
    local x0: (felt, felt, felt) = (v_sub_i[0] + i_dot_c, v_sub_i[1] + i_dot_c, v_sub_i[2] + i_dot_c);

    // Other corners
    let g_x = is_le(x0[1], x0[0]);  // step implementation
    let g_y = is_le(x0[2], x0[1]);
    let g_z = is_le(x0[0], x0[2]);
    local g: (felt, felt, felt) = (g_x * Math64x61.ONE, g_y * Math64x61.ONE, g_z * Math64x61.ONE);

    let i1_x = Math64x61.min(g[0], Math64x61.ONE - g[2]);
    let i1_y = Math64x61.min(g[1], Math64x61.ONE - g[0]);
    let i1_z = Math64x61.min(g[2], Math64x61.ONE - g[1]);
    local i1: (felt, felt, felt) = (i1_x, i1_y, i1_z);

    let i2_x = Math64x61.max(g[0], Math64x61.ONE - g[2]);
    let i2_y = Math64x61.max(g[1], Math64x61.ONE - g[0]);
    let i2_z = Math64x61.max(g[2], Math64x61.ONE - g[1]);
    local i2: (felt, felt, felt) = (i2_x, i2_y, i2_z);

    let x0_sub_i1 = Vec64x61.sub(x0, i1);
    let x1 = Vec64x61.add(x0_sub_i1, (C[0], C[0], C[0]));

    // 2.0*C.x = 1/3 = C.y
    let x0_sub_i2 = Vec64x61.sub(x0, i2);
    let x2 = Vec64x61.add(x0_sub_i2, (C[1], C[1], C[1]));

    // -1.0+3.0*C.x = -0.5 = -D.y
    let x3 = Vec64x61.sub(x0, (D[1], D[1], D[1]));

    // Permutations
    let i_mod_x = _mod289(i[0]);
    let i_mod_y = _mod289(i[1]);
    let i_mod_z = _mod289(i[2]);

    let perm1 = _permute_v4((
      i_mod_z + 0,
      i_mod_z + i1[2],
      i_mod_z + i2[2],
      i_mod_z + Math64x61.ONE
    ));

    let perm2 = _permute_v4((
      perm1[0] + i_mod_y + 0,
      perm1[1] + i_mod_y + i1[1],
      perm1[2] + i_mod_y + i2[1],
      perm1[3] + i_mod_y + Math64x61.ONE
    ));

    let p = _permute_v4((
      perm2[0] + i_mod_x + 0,
      perm2[1] + i_mod_x + i1[0],
      perm2[2] + i_mod_x + i2[0],
      perm2[3] + i_mod_x + Math64x61.ONE
    ));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    local ns: (felt, felt, felt) = (658812288346769701, -2141139937127001526, 329406144173384851);

    // p - 49.0 * floor(p * ns.z * ns.z); // mod(p,7*7)
    let p_ns = _mul_v4(p, ns[2]);
    let p_ns_2 = _mul_v4(p_ns, ns[2]);
    let p_ns_2_fl = _floor_v4(p_ns_2);
    let p_fl_49 = _mul_v4(p_ns_2_fl, 49 * Math64x61.ONE);
    local j: (felt, felt, felt, felt) = (
      p[0] - p_fl_49[0],
      p[1] - p_fl_49[1],
      p[2] - p_fl_49[2],
      p[3] - p_fl_49[3]
    );

    // x_ = floor(j * ns.z);
    // y_ = floor(j - 7.0 * x_ ); // mod(j,N)
    let j_ns = _mul_v4(j, ns[2]);
    let x_ = _floor_v4(j_ns);
    let x_7 = _mul_v4(x_, 7 * Math64x61.ONE);
    local j_sub_x_7: (felt, felt, felt, felt) = (
      j[0] - x_7[0],
      j[1] - x_7[1],
      j[2] - x_7[2],
      j[3] - x_7[3]
    );

    let y_ = _floor_v4(j_sub_x_7);

    // x = x_ *ns.x + ns.yyyy;
    // y = y_ *ns.x + ns.yyyy;
    // h = 1.0 - abs(x) - abs(y);
    let x_ns = _mul_v4(x_, ns[0]);
    local x: (felt, felt, felt, felt) = (
      x_ns[0] + ns[1],
      x_ns[1] + ns[1],
      x_ns[2] + ns[1],
      x_ns[3] + ns[1]
    );

    let y_ns = _mul_v4(y_, ns[0]);
    local y: (felt, felt, felt, felt) = (
      y_ns[0] + ns[1],
      y_ns[1] + ns[1],
      y_ns[2] + ns[1],
      y_ns[3] + ns[1]
    );

    let x_abs = _abs_v4(x);
    let y_abs = _abs_v4(y);
    local h: (felt, felt, felt, felt) = (
      Math64x61.ONE - x_abs[0] - y_abs[0],
      Math64x61.ONE - x_abs[1] - y_abs[1],
      Math64x61.ONE - x_abs[2] - y_abs[2],
      Math64x61.ONE - x_abs[3] - y_abs[3]
    );

    // b0 = vec4( x.xy, y.xy );
    // b1 = vec4( x.zw, y.zw );
    // s0 = floor(b0)*2.0 + 1.0;
    // s1 = floor(b1)*2.0 + 1.0;
    let b0_fl = _floor_v4((x[0], x[1], y[0], y[1]));
    local s0: (felt, felt, felt, felt) = (
      b0_fl[0] * 2 + Math64x61.ONE,
      b0_fl[1] * 2 + Math64x61.ONE,
      b0_fl[2] * 2 + Math64x61.ONE,
      b0_fl[3] * 2 + Math64x61.ONE
    );

    let b1_fl = _floor_v4((x[2], x[3], y[2], y[3]));
    local s1: (felt, felt, felt, felt) = (
      b1_fl[0] * 2 + Math64x61.ONE,
      b1_fl[1] * 2 + Math64x61.ONE,
      b1_fl[2] * 2 + Math64x61.ONE,
      b1_fl[3] * 2 + Math64x61.ONE
    );

    // sh = -step(h, vec4(0.0));
    let hx_le = is_le(0, h[0]);
    let hy_le = is_le(0, h[1]);
    let hz_le = is_le(0, h[2]);
    let hw_le = is_le(0, h[3]);
    local sh: (felt, felt, felt, felt) = (
      hx_le * Math64x61.ONE - Math64x61.ONE,
      hy_le * Math64x61.ONE - Math64x61.ONE,
      hz_le * Math64x61.ONE - Math64x61.ONE,
      hw_le * Math64x61.ONE - Math64x61.ONE
    );

    // a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    // a1 = b1.xzyw + s1.xzyw*sh.zzww ;
    let s0x_shx = Math64x61.mul(s0[0], sh[0]);
    let s0z_shx = Math64x61.mul(s0[2], sh[0]);
    let s0y_shy = Math64x61.mul(s0[1], sh[1]);
    let s0w_shy = Math64x61.mul(s0[3], sh[1]);

    let s1x_shz = Math64x61.mul(s1[0], sh[2]);
    let s1z_shz = Math64x61.mul(s1[2], sh[2]);
    let s1y_shw = Math64x61.mul(s1[1], sh[3]);
    let s1w_shw = Math64x61.mul(s1[3], sh[3]);

    // p0 = vec3(a0.xy,h.x);
    // p1 = vec3(a0.zw,h.y);
    // p2 = vec3(a1.xy,h.z);
    // p3 = vec3(a1.zw,h.w);
    local p0: (felt, felt, felt) = (x[0] + s0x_shx, y[0] + s0z_shx, h[0]);
    local p1: (felt, felt, felt) = (x[1] + s0y_shy, y[1] + s0w_shy, h[1]);
    local p2: (felt, felt, felt) = (x[2] + s1x_shz, y[2] + s1z_shz, h[2]);
    local p3: (felt, felt, felt) = (x[3] + s1y_shw, y[3] + s1w_shw, h[3]);

    // norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    // 1.79284291400159 - 0.85373472095314 * r;
    let p0_dot = Vec64x61.dot(p0, p0);
    let p1_dot = Vec64x61.dot(p1, p1);
    let p2_dot = Vec64x61.dot(p2, p2);
    let p3_dot = Vec64x61.dot(p3, p3);

    let p_dot_tis = _mul_v4((p0_dot, p1_dot, p2_dot, p3_dot), 1968578238032801632);
    const _tisv = 4134014299868874204;
    local norm: (felt, felt, felt, felt) = (
      _tisv - p_dot_tis[0],
      _tisv - p_dot_tis[1],
      _tisv - p_dot_tis[2],
      _tisv - p_dot_tis[3]
    );

    // p0 *= norm.x;
    // p1 *= norm.y;
    // p2 *= norm.z;
    // p3 *= norm.w;
    let p0 = Vec64x61.mul(p0, norm[0]);
    let p1 = Vec64x61.mul(p1, norm[1]);
    let p2 = Vec64x61.mul(p2, norm[2]);
    let p3 = Vec64x61.mul(p3, norm[3]);

    // m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    let x0_x0 = Vec64x61.dot(x0, x0);
    let x1_x1 = Vec64x61.dot(x1, x1);
    let x2_x2 = Vec64x61.dot(x2, x2);
    let x3_x3 = Vec64x61.dot(x3, x3);

    let x0_max = Math64x61.max(1383505805528216371 - x0_x0, 0);
    let x1_max = Math64x61.max(1383505805528216371 - x1_x1, 0);
    let x2_max = Math64x61.max(1383505805528216371 - x2_x2, 0);
    let x3_max = Math64x61.max(1383505805528216371 - x3_x3, 0);

    // m = m * m;
    let mx = Math64x61.mul(x0_max, x0_max);
    let my = Math64x61.mul(x1_max, x1_max);
    let mz = Math64x61.mul(x2_max, x2_max);
    let mw = Math64x61.mul(x3_max, x3_max);

    // res = 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
    let mx = Math64x61.mul(mx, mx);
    let my = Math64x61.mul(my, my);
    let mz = Math64x61.mul(mz, mz);
    let mw = Math64x61.mul(mw, mw);

    let p0_x0 = Vec64x61.dot(p0, x0);
    let p1_x1 = Vec64x61.dot(p1, x1);
    let p2_x2 = Vec64x61.dot(p2, x2);
    let p3_x3 = Vec64x61.dot(p3, x3);

    let mx_0 = Math64x61.mul(mx, p0_x0);
    let my_1 = Math64x61.mul(my, p1_x1);
    let mz_2 = Math64x61.mul(mz, p2_x2);
    let mw_3 = Math64x61.mul(mw, p3_x3);

    local res_sum = mx_0 + my_1 + mz_2 + mw_3;
    return Math64x61.mul(res_sum, 42 * Math64x61.ONE);
  }

  // Returns multiple octaves of noise with a persistence dropoff
  // @param v {fixed[]} A 3d point
  // @param octaves {integer} The number of iterations to add together
  // @param persistence {fixed} Value used to decrease (or increase) the impact of each iteration
  func noise3_octaves{range_check_ptr}(v: (felt, felt, felt), octaves: felt, persistence: felt) -> felt {
    let noise = _noise3_octaves_loop{persistence = persistence, v = v}(
      noise = 0, octaves = octaves, scale = Math64x61.ONE, total_range = 0
    );

    return noise;
  }

  // Returns the average noise value given a percentile for a single octave of simplex noise scaled
  // to a range from 0 to 1
  // @param percentile {fixed} Value indicating the percentile (between 0 and 1)
  func noise3_at_percentile{range_check_ptr}(percentile: felt) -> felt {
    alloc_locals;
    let upper_half = is_le(1152921504606846976, percentile); // 0.5
    let inverse = Math64x61.ONE - percentile;
    let perc = upper_half * inverse + percentile - upper_half * percentile;
    let perc = Math64x61.mul(perc, Math64x61.ONE * 100);
    let (dist_data) = _simplex_dist_data();
    let slot = Math64x61.toFelt(perc);
    let whole_noise_val = dist_data[slot];
    let next_noise_val = dist_data[slot + 1];
    let whole_perc = Math64x61.floor(perc);
    let fract_perc = perc - whole_perc;
    let partial_noise_val = Math64x61.mul(fract_perc, next_noise_val - whole_noise_val);

    if (upper_half == 1) {
      return Math64x61.ONE - whole_noise_val - partial_noise_val;
    }

    return whole_noise_val + partial_noise_val;
  }

  func _noise3_octaves_loop{range_check_ptr, persistence: felt, v: (felt, felt, felt)}(
      noise: felt, octaves: felt, scale: felt, total_range: felt
    ) -> felt {
    if (octaves == 0) {
      let normalized_noise = Math64x61.div(noise, total_range);
      return normalized_noise;
    }

    let resized_point = Vec64x61.div(v, scale);
    let current_noise = noise3(resized_point);
    let scaled_noise = Math64x61.mul(current_noise, scale);
    let new_scale = Math64x61.mul(scale, persistence);
    return _noise3_octaves_loop(
      noise = noise + scaled_noise,
      octaves = octaves - 1,
      scale = new_scale,
      total_range = total_range + scale
    );
  }
}

// Calculate x mod 289
// x - floor(x * (1.0 / 289.0)) * 289.0;
func _mod289{range_check_ptr}(x: felt) -> felt {
  alloc_locals;

  local div = 289 * Math64x61.ONE;
  let (_, rem) = signed_div_rem(x, div, Math64x61.BOUND);
  return rem;
}

func _permute{range_check_ptr}(x: felt) -> felt {
  let x_34 = Math64x61.mul(x, 34 * Math64x61.ONE);
  let mod_arg = Math64x61.mul(x_34 + Math64x61.ONE, x);
  return _mod289(mod_arg);
}

func _permute_v4{range_check_ptr}(a: (felt, felt, felt, felt)) -> (felt, felt, felt, felt) {
  let res_x = _permute(a[0]);
  let res_y = _permute(a[1]);
  let res_z = _permute(a[2]);
  let res_w = _permute(a[3]);
  return (res_x, res_y, res_z, res_w);
}

// Convenience function to return element-wise floor of a 3D vector
func _floor_v3{range_check_ptr}(a: (felt, felt, felt)) -> (felt, felt, felt) {
  let res_x = Math64x61.floor(a[0]);
  let res_y = Math64x61.floor(a[1]);
  let res_z = Math64x61.floor(a[2]);
  return (res_x, res_y, res_z);
}

// Convenience function to return element-wise floor of a 4D vector
func _floor_v4{range_check_ptr}(a: (felt, felt, felt, felt)) -> (felt, felt, felt, felt) {
  let res_x = Math64x61.floor(a[0]);
  let res_y = Math64x61.floor(a[1]);
  let res_z = Math64x61.floor(a[2]);
  let res_w = Math64x61.floor(a[3]);
  return (res_x, res_y, res_z, res_w);
}

func _mul_v4{range_check_ptr}(a: (felt, felt, felt, felt), b: felt) -> (
  felt, felt, felt, felt
) {
  let res_x = Math64x61.mul(a[0], b);
  let res_y = Math64x61.mul(a[1], b);
  let res_z = Math64x61.mul(a[2], b);
  let res_w = Math64x61.mul(a[3], b);
  return (res_x, res_y, res_z, res_w);
}

func _abs_v4{range_check_ptr}(a: (felt, felt, felt, felt)) -> (felt, felt, felt, felt) {
  let res_x = abs_value(a[0]);
  let res_y = abs_value(a[1]);
  let res_z = abs_value(a[2]);
  let res_w = abs_value(a[3]);
  return (res_x, res_y, res_z, res_w);
}

// Cumulative probablity distribution (up to 50%) for simplex3D in 64.61
func _simplex_dist_data() -> (data: felt*) {
  let (data_address) = get_label_location(data_start);
  return (data = cast(data_address, felt*));

  data_start:
  dw 0;
  dw 271799274386227200;
  dw 319122254845706240;
  dw 358634304701464576;
  dw 393079804976431104;
  dw 425836455391133696;
  dw 456411674736328704;
  dw 484699909895749632;
  dw 511088188962373632;
  dw 536209830633799680;
  dw 559853728677494784;
  dw 582442095558524928;
  dw 604150853137334272;
  dw 624592973320945664;
  dw 643979562341892096;
  dw 662275435828084736;
  dw 679973174988767232;
  dw 696932042335584256;
  dw 713539065961512960;
  dw 729512770889842688;
  dw 745134632097284096;
  dw 760650940188459008;
  dw 775780220186656768;
  dw 790346550231433216;
  dw 804736958415765504;
  dw 819092182228008960;
  dw 833271484179808256;
  dw 847274864271163392;
  dw 860926400641630208;
  dw 874366830779564032;
  dw 887596154684964864;
  dw 900649556729921536;
  dw 913843696263233536;
  dw 927178573284900864;
  dw 940548634678657024;
  dw 953813142956146688;
  dw 966866545001103360;
  dw 979990315790237696;
  dw 993114086579372032;
  dw 1006132304252239872;
  dw 1019009784436752384;
  dw 1032203923970064384;
  dw 1045644354107998208;
  dw 1058979231129665536;
  dw 1072349292523421696;
  dw 1085719353917177856;
  dw 1098983862194667520;
  dw 1112037264239624192;
  dw 1124809191307870208;
  dw 1137757040236560384;
  dw 1152921504606846976;
}
