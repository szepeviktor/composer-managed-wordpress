### Custom index for posts table

```sql
ALTER TABLE `wp_posts` ADD fulltext(`post_title`);
```
