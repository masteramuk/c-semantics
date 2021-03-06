#include <stdlib.h>

struct treeNode {
  int value;
  struct treeNode *left;
  struct treeNode *right;
};

struct treeNode* new_node(int v);
int find_min(struct treeNode *t);

struct treeNode* delete(int v, struct treeNode *t)
{
  int min;

  if (t == NULL)
    return NULL;

  if (v == t->value) {
    if (t->left == NULL) {
      struct treeNode *tmp;

      tmp = t->right;
      free(t);

      return tmp;
    }
    else if (t->right == NULL) {
      struct treeNode *tmp;

      tmp = t->left;
      free(t);

      return tmp;
    }
    else {
      min = find_min(t->right);
      t->right = delete(min, t->right);
      t->value = min;
    }
  }
  else if (v < t->value)
    t->left = delete(v, t->left);
  else
    t->right = delete(v, t->right);

  return t;
}

int find(int v, struct treeNode *t)
{
  if (t == NULL) return 0;
  if (v == t->value) return 1;
  if (v < t->value) return find(v, t->left);
  return find(v, t->right);
}

struct treeNode* insert(int v, struct treeNode *t)
{
  if (t == NULL)
    return new_node(v);

  if (v < t->value)
    t->left = insert(v, t->left);
  else if (v > t->value)
    t->right = insert(v, t->right);

  return t;
}

struct treeNode* new_node(int v)
{
  struct treeNode *node;
  node = (struct treeNode *) malloc(sizeof(struct treeNode));
  node->value = v;
  node->left = node->right = NULL;
  return node;
}

int find_min(struct treeNode *t)
{
  if (t->left == NULL) return t->value;
  return find_min(t->left);
}

int main()
{
  struct treeNode *t = NULL;
  for (int v = 0; v < 5; v++) {
    t = insert(v, t);
  }
  for (int v = 0; v < 5; v++) {
    t = delete(v, t);
  }

  return t == NULL;
}
