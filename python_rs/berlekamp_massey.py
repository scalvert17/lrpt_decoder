import galois
GF = galois.GF(2**8, irreducible_poly="x^8 + x^7 + x^2 + x + 1", repr="power")
#GF = galois.GF(2**3, irreducible_poly="x^3 + x + 1", repr="power")  # Testing polynomial


def gfelem_list_to_poly(gf_list):
    """
    Convert list of gf elements to galois.Poly. Must already
    be in desceding x order.
    """
    to_poly_list = []
    for elem in gf_list:
        to_poly_list.append(int(elem))
    
    return galois.Poly(to_poly_list, field=GF)


def berlekamp_massey(syndrome_poly, t=16):
    """
    Inputs:
      syndromes: galois.Poly; The syndrome polynomial S31*x^31, S31*x^30, ... , S1*x^1, S0*x^0.
    
    Outputs:
      lambda:    galois.Poly; The lambda polynomial lambda16*x^16, lambda*x^15, ... , lambda1*x^1, 1.
    """
    # Initialize C and B to 16+1 coeff long polynomials. All coeffs 1. Descending x order.
    C_poly = galois.Poly.One(field=GF)
    B_poly = galois.Poly.One(field=GF)
    L = 0
    m = 1
    b = GF(1)
    x = galois.Poly([1, 0], field=GF)
    N = 2*t


    for n in range(1, N+1):  # t=16(1, 2, ..., 32)

        # COMPUTE DELTA_R
        """ C_poly_coeffs = list(C_poly.coefficients())
        C_poly_coeffs.reverse()
        syndrome_poly_coeffs = list(syndrome_poly.coefficients())
        syndrome_poly_coeffs.reverse()

        delta = syndrome_poly.coefficients()[-(n+1)]
        for j in range(1, (L+1)):
             delta += C_poly_coeffs[j] * syndrome_poly_coeffs[n - j] """
        
        delta = GF(0)
        for j in range(L+1):
            #Reverse indexing. j=0 index=-1,  j=1 index=-2, index=-(j+1)
            delta += C_poly.coefficients()[-(j+1)] * syndrome_poly.coefficients()[-(n-j)]

        
        if (delta == GF(0)):
            B_poly = B_poly * x

        elif ((2*L <= (n-1))):
            T_poly = C_poly - (delta * x * B_poly)
            B_poly = (delta ** (-1)) * C_poly
            C_poly = T_poly
            L = n - L
        
        else:
            T_poly = C_poly - (delta * x * B_poly)
            C_poly = T_poly
            B_poly = B_poly * x

    return C_poly

