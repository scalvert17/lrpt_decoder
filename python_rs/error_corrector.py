import galois
GF = galois.GF(2**8, irreducible_poly="x^8 + x^7 + x^2 + x + 1", repr="poly")
#GF = galois.GF(2**3, irreducible_poly="x^3 + x + 1", repr="power")  # Testing polynomial


def error_corrector(code_word, error_locs, error_mags):
    """
    Inputs:
      code_word:  galois.Poly; In descending x order. Is reversed in the function.
      error_locs: list;        list of GF(2^8) element type error locs. They're powers of alpha and the
                               power corresponds to the x location in the code word. For example,
                               X=alpha^34 means the x^34 code word element has an error.
      error_mags: list;        list of GF(2^8) element type error mags. At each error location, just
                               subtract the corresponding error magnitude.

    Outputs:
        code_word_out: galois.Poly; In descending x order. The corrected code_word with the parity bits still
                                    appended.
    """
    # code_word is recieved in descending order. Reverse for easily understood indexing.
    code_word_coeffs = [GF(coeff) for coeff in code_word.coefficients()]
    code_word_coeffs.reverse()

    for i, loc_power in enumerate(error_locs):
        loc_index = loc_power.log()

        # Subtract the error magnitude from the code_word value at the correspoding location
        code_word_coeffs[loc_index] = code_word_coeffs[loc_index] - error_mags[i]
    
    code_word_coeffs.reverse()
    code_word_poly = gfelem_list_to_poly(code_word_coeffs)
    return code_word_poly


def gfelem_list_to_poly(gf_list):
    """
    Convert list of gf elements to galois.Poly. Must already
    be in desceding x order.
    """
    to_poly_list = []
    for elem in gf_list:
        to_poly_list.append(int(elem))
    
    return galois.Poly(to_poly_list, field=GF)

