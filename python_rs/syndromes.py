import galois
GF = galois.GF(2**8, irreducible_poly="x^8 + x^7 + x^2 + x + 1", repr="int")


def gfelem_list_to_poly(gf_list):
    """
    Convert list of gf elements to galois.Poly. Must already
    be in desceding x order.
    """
    to_poly_list = []
    for elem in gf_list:
        to_poly_list.append(int(elem))
    
    return galois.Poly(to_poly_list, field=GF)


def syndromes_finder(code_word_poly):
    """
    Inputs:
      code_word: galois.Poly; Descending x order. Length=255

    Outputs:
      syndromes: galois.Poly; The syndrome polynomial S31*x^31, S30*x^30, ... , S1*x^1, S0*x^0.

    This function takes in a code word in descending x order (m222*x^254, m221*x^253, ... , m0*x^32, p31*x^31, p30*x^30, ... , p1*x, p0)
    where ms are the message elements and ps are the parity elements.
    """
    alpha = GF(2)
    syndromes = []

    for j in range(112, 144):
        zero = alpha**(11*j)
        syndromes.append(code_word_poly(zero))
    
    syndromes.reverse()
    return gfelem_list_to_poly(syndromes)

