import unittest

from inventory import color, oklch_values


class InventoryColorTests(unittest.TestCase):
    def test_achromatic_hue_none_from_tailwind_neutral_palette(self):
        # CSS 'none' is valid for achromatic colors used by Banner.Action.
        self.assertEqual(oklch_values('oklch(37.1% 0 none)'), [.371, 0, 0])
        self.assertEqual(color('oklch(37.1% 0 none)'), 'ff404040')
        self.assertEqual(color('oklch(100% 0 none)'), 'ffffffff')
        self.assertEqual(color('oklch(0% 0 none)'), 'ff000000')


if __name__ == '__main__':
    unittest.main()
