"""Add some documentation here."""

import rules_python.tests.math as math

def main() -> None:
    result = math.sum(10, 20)
    print(f"-- Calculator --")
    print(f"10 + 20 = {result}")

if __name__ == "__main__":
    main()
