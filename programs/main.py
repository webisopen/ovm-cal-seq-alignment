import math
import sys
from typing import Union
import eth_abi
import ovm

bridge = ovm.Bridge()


def cal_pi(n: int) -> Union[bool, str]:
    if n > 15:
        raise ValueError("n must be less than 15")

    return True, format(math.pi, f".{n}f")


def main():
    if len(sys.argv) != 2:
        raise ValueError("missing messages argument")

    (input,) = eth_abi.decode(["int"], bytes.fromhex(sys.argv[1]))

    bridge.submit(["bool", "string"], [True, cal_pi(input)])


if __name__ == "__main__":
    main()
