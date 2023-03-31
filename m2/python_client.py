import ctypes
import os

class VectorDatabase:
    def __init__(self, num_vectors, vector_size):
        self.lib = ctypes.CDLL('./vector_db_lib.so')
        self.db = ctypes.c_void_p(self.lib.init(num_vectors, vector_size))

    def upsert(self, index, vector):
        vector_size = len(vector)
        float_array = ctypes.c_float * vector_size
        self.lib.upsert(self.db, ctypes.c_int(index), float_array(*vector), ctypes.c_int(vector_size))

    def search(self, query_vector):
        vector_size = len(query_vector)
        float_array = ctypes.c_float * vector_size
        return self.lib.search(self.db, float_array(*query_vector), ctypes.c_int(vector_size))

    def delete(self, index):
        self.lib.delete(self.db, ctypes.c_int(index))

def main():
    num_vectors = 10
    vector_size = 3

    db = VectorDatabase(num_vectors, vector_size)

    vector1 = [0.5, 0.2, 0.1]
    vector2 = [0.9, 0.5, 0.7]
    vector3 = [0.1, 0.8, 0.3]

    db.upsert(0, vector1)
    db.upsert(1, vector2)
    db.upsert(2, vector3)

    query_vector = [0.4, 0.6, 0.3]
    most_similar_index = db.search(query_vector)
    print(f"The most similar vector to {query_vector} is at index: {most_similar_index}")

    db.delete(1)

    most_similar_index = db.search(query_vector)
    print(f"After deleting vector at index 1, the most similar vector to {query_vector} is at index: {most_similar_index}")

if __name__ == "__main__":
    main()
