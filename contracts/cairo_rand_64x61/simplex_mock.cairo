%lang starknet

from cairo_rand_64x61.simplex import Simplex

@view
func noise3_test{range_check_ptr}(v: (felt, felt, felt)) -> (res: felt) {
  let res = Simplex.noise3(v);
  return (res = res);
}

@view
func noise3_at_percentile_test{range_check_ptr}(percentile: felt) -> (res: felt) {
  let res = Simplex.noise3_at_percentile(percentile);
  return (res = res);
}

@view
func noise3_octaves_test{range_check_ptr}(v: (felt, felt, felt), octaves: felt, persistence: felt) -> (res: felt) {
  let res = Simplex.noise3_octaves(v, octaves, persistence);
  return (res = res);
}
