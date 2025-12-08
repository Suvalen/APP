Container(
    width: 412,
    height: 917,
    clipBehavior: Clip.antiAlias,
    decoration: ShapeDecoration(
        color: const Color(0xFFF7F8FA),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
        ),
    ),
    child: Stack(
        children: [
            Positioned(
                left: 213,
                top: 736,
                child: Container(
                    width: 165,
                    height: 57,
                    decoration: ShapeDecoration(
                        color: const Color(0x3F4267B2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 248,
                top: 754,
                child: Text(
                    'FACEBOOK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: const Color(0xFF4267B2),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.55,
                    ),
                ),
            ),
            Positioned(
                left: 34,
                top: 736,
                child: Container(
                    width: 165,
                    height: 57,
                    decoration: ShapeDecoration(
                        color: const Color(0x3FD44638),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 81,
                top: 754,
                child: Text(
                    'GOOGLE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: const Color(0xFFD44638),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.55,
                    ),
                ),
            ),
            Positioned(
                left: 110,
                top: 700,
                child: Text(
                    'Continue With Accounts',
                    style: TextStyle(
                        color: const Color(0xFFACADB9),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.16,
                    ),
                ),
            ),
            Positioned(
                left: 92,
                top: 606,
                child: Text.rich(
                    TextSpan(
                        children: [
                            TextSpan(
                                text: 'Create New Account?',
                                style: TextStyle(
                                    color: const Color(0xFFACADB9),
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.16,
                                ),
                            ),
                            TextSpan(
                                text: ' ',
                                style: TextStyle(
                                    color: const Color(0xFFACADB9),
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.16,
                                ),
                            ),
                            TextSpan(
                                text: 'Sign up',
                                style: TextStyle(
                                    color: const Color(0xFF323142),
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.32,
                                ),
                            ),
                        ],
                    ),
                ),
            ),
            Positioned(
                left: -1,
                top: 654,
                child: Opacity(
                    opacity: 0.30,
                    child: Container(
                        width: 414,
                        decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 1,
                                    strokeAlign: BorderSide.strokeAlignCenter,
                                    color: const Color(0xFFC2C3CB),
                                ),
                            ),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 34,
                top: 530.14,
                child: Container(
                    width: 344,
                    height: 67.06,
                    decoration: ShapeDecoration(
                        color: const Color(0xFF141718),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 184,
                top: 546,
                child: Text(
                    'Login',
                    style: TextStyle(
                        color: const Color(0xFFF3F5F6),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.32,
                    ),
                ),
            ),
            Positioned(
                left: 254,
                top: 473,
                child: Opacity(
                    opacity: 0.70,
                    child: Text(
                        'Forget Password ?',
                        style: TextStyle(
                            color: const Color(0xFF323142),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.28,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 34,
                top: 402.26,
                child: Container(
                    width: 344,
                    height: 67.06,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.84),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 96,
                top: 426.65,
                child: Text(
                    'Password',
                    style: TextStyle(
                        color: const Color(0xFFC2C3CB),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.28,
                    ),
                ),
            ),
            Positioned(
                left: 34,
                top: 315.22,
                child: Container(
                    width: 344,
                    height: 67.06,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.84),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 96,
                top: 341,
                child: Text(
                    'Enter Your Email',
                    style: TextStyle(
                        color: const Color(0xFFC2C3CB),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.28,
                    ),
                ),
            ),
            Positioned(
                left: 34,
                top: 163.81,
                child: SizedBox(
                    width: 300.32,
                    child: Text(
                        'Login Your\nAccount',
                        style: TextStyle(
                            color: const Color(0xFF323142),
                            fontSize: 38,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            letterSpacing: -1.52,
                        ),
                    ),
                ),
            ),
        ],
    ),
)