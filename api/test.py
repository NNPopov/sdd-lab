from typing import List

def two_sum(nums: List[int], target: int) -> List[int]:
    seen = {}

    for i, num in enumerate(nums):
        needed = target - num

        if needed in seen:
            return [seen[needed], i]

        seen[num] = i


nums = [2, 7, 1, 8]
target = 9

result  = two_sum(nums, target)

print(result)