# GPT4Memory

This is a project to get GPT4 to create its own memory in assembly. 

## Progress

Started creating the primitive operations of upsert, search and delete. I am running on an M2 mac which seems to be causing it some issues. I can compile the assembly but it is failing to work with the python bindings. 

Feel free to contribute. 

## Run

### Compile
```
as -o vector_database.o vector_database.s
clang -shared -o vector_database.dylib vector_database.o -lc
```

### Python 

```python
python python_client.py
```
