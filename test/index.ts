import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { XNft, XYZ } from "typechain";

describe("xNFT", () => {
  let xyzToken: XYZ;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let xNFT: XNft;

  beforeEach(async () => {
    const XYZFactory = await ethers.getContractFactory("XYZ");
    xyzToken = await XYZFactory.deploy();

    const xNftFactory = await ethers.getContractFactory("XNft");
    xNFT = (await upgrades.deployProxy(xNftFactory, [
      xyzToken.address,
    ])) as XNft;

    [owner, minter] = await ethers.getSigners();
  });

  it("should not allow mint if the user doesn't provide enough XYZ token", async () => {
    await expect(
      xNFT.mintTransfer(minter.address, "wow", "whoops")
    ).to.be.revertedWith("not allowed");
  });

  it("should allow mint if the user provides enough XYZ token", async () => {
    await xyzToken.transfer(minter.address, "100");
    await xyzToken.connect(minter).approve(xNFT.address, "100");
    await expect(xNFT.mintTransfer(minter.address, "wow", "whoops"))
      .to.emit(xNFT, "XNftMinted")
      .withArgs(minter.address, 1);
  });

  it("should increase fee gradually based on the scale", async () => {
    await xyzToken.transfer(minter.address, "1000");
    await xyzToken.connect(minter).approve(xNFT.address, "100");
    await expect(xNFT.mintTransfer(minter.address, "wow", "whoops"))
      .to.emit(xNFT, "XNftMinted")
      .withArgs(minter.address, 1);

    await xyzToken.connect(minter).approve(xNFT.address, "103");
    await expect(xNFT.mintTransfer(minter.address, "wow 2", "whoops 2"))
      .to.emit(xNFT, "XNftMinted")
      .withArgs(minter.address, 2);

    const balance = await xyzToken.balanceOf(minter.address);
    expect(balance).to.equal("797");
  });
});
