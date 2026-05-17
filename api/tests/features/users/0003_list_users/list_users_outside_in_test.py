# FEATURE: list_users — outside-in acceptance test.
#
# Covers: F1, F2, F3, F4, F7, F8, F9, F10 (see requirements.md).
# Red-state trigger: the current endpoint returns a fastcrud-shaped payload
# {"data": {...}, "has_more": ..., ...}; the new implementation must return
# {"items": [...], "total_count": ..., "page": ..., "items_per_page": ...}.
# The shape assertion on that first line catches the mismatch immediately.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/users"


async def test_list_users_happy_path_excludes_deleted(
    async_client: AsyncClient,
    make_user,
) -> None:
    """Scenario 1 — seeded active users appear; soft-deleted user is absent."""
    active_1 = await make_user()
    active_2 = await make_user()
    active_3 = await make_user()
    deleted = await make_user(is_deleted=True)

    # Use a large page to retrieve all users in one call.
    response = await async_client.get(_ENDPOINT, params={"items_per_page": 500})

    assert response.status_code == 200, response.text
    body = response.json()

    # ── Shape assertion — primary RED trigger ────────────────────────────────
    # fastcrud returns {"data": {...}, "has_more": ..., "total_count": ..., ...}
    # The new slice returns {"items": [...], "total_count": ..., "page": ..., "items_per_page": ...}
    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}, (
        f"Unexpected top-level keys: {set(body.keys())}"
    )

    assert isinstance(body["items"], list)
    assert body["page"] == 1
    assert body["items_per_page"] == 500

    returned_usernames = {item["username"] for item in body["items"]}

    # Active seeded users must be present.
    assert active_1.username in returned_usernames, f"Active user '{active_1.username}' missing from listing"
    assert active_2.username in returned_usernames
    assert active_3.username in returned_usernames

    # Soft-deleted user must be absent.
    assert deleted.username not in returned_usernames, (
        f"Soft-deleted user '{deleted.username}' must not appear in listing"
    )

    # total_count must be consistent with the number of items returned.
    assert body["total_count"] == len(body["items"]), (
        "total_count must equal the number of non-deleted users, not just the page size"
    )

    # Each item must have the contracted fields.
    expected_fields = {"id", "name", "username", "email", "profile_image_url", "tier_id"}
    for item in body["items"]:
        assert expected_fields.issubset(item.keys()), f"Item missing required fields. Got: {set(item.keys())}"


async def test_list_users_pagination(
    async_client: AsyncClient,
    make_user,
) -> None:
    """Scenario 2 — page=2, items_per_page=3 returns a non-overlapping slice."""
    # Seed 10 users so page 2 with items_per_page=3 is guaranteed non-empty.
    seeded = [await make_user() for _ in range(10)]
    seeded_usernames = {u.username for u in seeded}

    page1_response = await async_client.get(_ENDPOINT, params={"page": 1, "items_per_page": 3})
    assert page1_response.status_code == 200, page1_response.text

    page2_response = await async_client.get(_ENDPOINT, params={"page": 2, "items_per_page": 3})
    assert page2_response.status_code == 200, page2_response.text

    body = page2_response.json()

    # ── Shape assertion — primary RED trigger ────────────────────────────────
    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}, (
        f"Unexpected top-level keys: {set(body.keys())}"
    )

    assert body["page"] == 2
    assert body["items_per_page"] == 3
    assert len(body["items"]) == 3, f"Expected exactly 3 items on page 2, got {len(body['items'])}"

    # Page 1 and page 2 must return disjoint sets of users.
    page1_usernames = {item["username"] for item in page1_response.json()["items"]}
    page2_usernames = {item["username"] for item in body["items"]}
    assert page1_usernames.isdisjoint(page2_usernames), (
        f"Pages must not overlap. Page 1: {page1_usernames}, Page 2: {page2_usernames}"
    )

    # Our 10 seeded users must collectively appear somewhere across the pages.
    # Fetch a large page to confirm all are present (no duplicates, no gaps).
    all_response = await async_client.get(_ENDPOINT, params={"items_per_page": 500})
    all_usernames = {item["username"] for item in all_response.json()["items"]}
    assert seeded_usernames.issubset(all_usernames), (
        f"Some seeded users missing from full listing: {seeded_usernames - all_usernames}"
    )
