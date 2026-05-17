# FEATURE: posts — repository (FastCRUD instance).
from fastcrud import FastCRUD

from ...adapters.db.models.post import Post
from .schemas import PostCreateInternal, PostDelete, PostRead, PostUpdate, PostUpdateInternal

CRUDPost = FastCRUD[Post, PostCreateInternal, PostUpdate, PostUpdateInternal, PostDelete, PostRead]
crud_posts = CRUDPost(Post)
