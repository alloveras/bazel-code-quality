import unittest
import rules_python.tests.math as math

class TestMathOperators(unittest.TestCase):

    def test_sum(self):
        self.assertEqual(30, math.sum(10, 20))


if __name__ == '__main__':
    unittest.main()
