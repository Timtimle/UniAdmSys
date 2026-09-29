from app.rag import LocalDocumentRetriever


def test_local_retriever_admission():
    retriever = LocalDocumentRetriever("data/admission_docs")
    results = retriever.search("hồ sơ tuyển sinh học bạ")
    assert len(results) >= 1
    assert any("admission_rules_demo.md" == x["source"] for x in results)


def test_local_retriever_tuition():
    retriever = LocalDocumentRetriever("data/admission_docs")
    results = retriever.search("học phí Software Engineering")
    assert len(results) >= 1
    assert any("tuition_demo.md" == x["source"] for x in results)


def test_local_retriever_ielts():
    retriever = LocalDocumentRetriever("data/admission_docs")
    results = retriever.search("IELTS quy đổi điểm")
    assert len(results) >= 1
    assert any("faq_demo.md" == x["source"] for x in results)
