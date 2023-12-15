import galois
GF = galois.GF(2**8, irreducible_poly="x^8 + x^7 + x^2 + x + 1", repr="int")
#GF = galois.GF(2**3, irreducible_poly="x^3 + x + 1", repr="power")  # Testing polynomial


def rs_error_evaluator_poly(lambda_poly, syndrome_poly):
    """
    Inputs:
      lambda_poly: galois.Poly; descending order of x (x^3, x^2, x, 1)
      syndromes:   galois.Poly; descending order of x (x^3, x^2, x, 1)

    Output:
      omega_poly:  galois.Poly; descending order of x (x^3, x^2, x, 1)

    Solves the key equation
      omega_poly(x) = lambda_poly(x)*syndromes(x) mod x^32
    to find omega_poly. Uses the galois library to perform arithmetic.
    """
    omega_list = []

    # Create the x^32 term
    x_32 = galois.Poly([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], field=GF)
    x_4 = galois.Poly([1, 0, 0, 0, 0], field=GF)
    print(x_32)

    # Compute omega
    omega_poly = ((lambda_poly * syndrome_poly) % x_32)

    return omega_poly



