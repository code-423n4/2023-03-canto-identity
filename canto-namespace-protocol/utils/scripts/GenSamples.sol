// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../../src/Tray.sol";

contract GenSamples {
    address constant HEVM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    function run() public {
        genSVGEmojis();
        font1();
        otherFonts();
        sampleTiles();
    }

    function genSVGEmojis() public {
        Tray.TileData[] memory _tiles = new Tray.TileData[](7);
        uint256 numGenerated;
        for (uint256 i; i < 420; ++i) {
            uint256 numModifier;
            if (i == 15 || i == 16 || (i >= 383 - 47 && i < 383)) {
                numModifier = 5;
            }
            for (uint256 modifierIndex; modifierIndex <= numModifier; ++modifierIndex) {
                Tray.TileData memory tileData;
                tileData.fontClass = 0;
                tileData.characterIndex = uint16(i);
                tileData.characterModifier = uint8(modifierIndex);
                _tiles[numGenerated % 7] = tileData;
                if ((numGenerated > 0 && (numGenerated + 1) % 7 == 0) || i == 419) {
                    vm.writeFile(
                        string.concat("utils/data/emojis", vm.toString(numGenerated / 7), ".svg"),
                        Utils.generateSVG(_tiles, true)
                    );
                    _tiles = new Tray.TileData[](7);
                }
                numGenerated++;
            }
        }
    }

    function font1() public {
        Tray.TileData[] memory _tiles = new Tray.TileData[](7);
        for (uint256 i; i < 42; ++i) {
            Tray.TileData memory tileData;
            tileData.fontClass = 1;
            tileData.characterIndex = uint16(i % 36);
            _tiles[i % 7] = tileData;
            if ((i > 0 && (i + 1) % 7 == 0)) {
                vm.writeFile(
                    string.concat("utils/data/font1_", vm.toString(i / 7), ".svg"),
                    Utils.generateSVG(_tiles, true)
                );
                _tiles = new Tray.TileData[](7);
            }
        }
    }

    function otherFonts() public {
        Tray.TileData[] memory _tiles = new Tray.TileData[](7);
        uint256 startingFont;
        for (uint256 i; i < 8 * 26; ++i) {
            Tray.TileData memory tileData;
            uint256 fontNumber = 2 + i / 26;
            if (i % 7 == 0) startingFont = fontNumber;
            tileData.fontClass = uint8(fontNumber);
            tileData.characterIndex = uint16(i % 26);
            tileData.characterModifier = uint8(i);
            _tiles[i % 7] = tileData;
            if ((i > 0 && (i + 1) % 7 == 0) || i == 8 * 26 - 1) {
                vm.writeFile(
                    string.concat("utils/data/font", vm.toString(startingFont), "_", vm.toString(i / 7), ".svg"),
                    Utils.generateSVG(_tiles, true)
                );
                _tiles = new Tray.TileData[](7);
            }
        }
    }

    function sampleTiles() public {
        Tray.TileData[] memory _tiles = new Tray.TileData[](7);
        _tiles[0].fontClass = 0;
        _tiles[0].characterIndex = 20;
        _tiles[1].fontClass = 1;
        _tiles[2].fontClass = 1;
        _tiles[2].characterIndex = 29;
        _tiles[3].fontClass = 2;
        _tiles[3].characterIndex = 7;
        _tiles[4].fontClass = 3;
        _tiles[4].characterIndex = 16;
        _tiles[5].fontClass = 4;
        _tiles[5].characterIndex = 9;
        _tiles[6].fontClass = 5;
        _tiles[6].characterIndex = 17;
        vm.writeFile(string.concat("utils/data/sample_tray1.svg"), Utils.generateSVG(_tiles, true));
        _tiles[0].fontClass = 6;
        _tiles[0].characterIndex = 20;
        _tiles[1].fontClass = 7;
        _tiles[1].characterIndex = 6;
        _tiles[1].characterModifier = 244;
        _tiles[2].characterIndex = 14;
        _tiles[2].fontClass = 8;
        _tiles[2].characterIndex = 25;
        _tiles[3].fontClass = 9;
        _tiles[3].characterIndex = 19;
        _tiles[4].fontClass = 0;
        _tiles[4].characterIndex = 83;
        _tiles[5].fontClass = 4;
        _tiles[5].characterIndex = 21;
        _tiles[6].fontClass = 5;
        _tiles[6].characterIndex = 23;
        vm.writeFile(string.concat("utils/data/sample_tray2.svg"), Utils.generateSVG(_tiles, true));
    }

    function testSampleName() public {
        Tray.TileData[] memory _tiles = new Tray.TileData[](5);
        _tiles[0].fontClass = 1;
        _tiles[0].characterIndex = 2;
        _tiles[1].fontClass = 2;
        _tiles[1].characterIndex = 0;
        _tiles[2].fontClass = 3;
        _tiles[2].characterIndex = 13;
        _tiles[3].fontClass = 4;
        _tiles[3].characterIndex = 19;
        _tiles[4].fontClass = 9;
        _tiles[4].characterIndex = 14;
        vm.writeFile(string.concat("utils/data/sample_name.svg"), Utils.generateSVG(_tiles, false));
    }
}
