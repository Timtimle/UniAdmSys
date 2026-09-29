from app.rag import LocalDocumentRetriever


def test_local_retriever():
    retriever = LocalDocumentRetriever("data/admission_docs")
    results = retriever.search("official admission decision")
    assert len(results) >= 1
