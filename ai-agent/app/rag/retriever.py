from __future__ import annotations

import re
from pathlib import Path


class LocalDocumentRetriever:

    def __init__(self, docs_dir: str = "data/admission_docs"):
        self.docs_dir = Path(docs_dir)

    @staticmethod
    def _tokens(text: str) -> set[str]:
        return {
            token.lower()
            for token in re.findall(r"\w+", text, flags=re.UNICODE)
            if len(token) > 2
        }

    def _chunks(self) -> list[dict]:
        chunks: list[dict] = []
        if not self.docs_dir.exists():
            return chunks

        for path in sorted(self.docs_dir.glob("*")):
            if path.suffix.lower() not in {".md", ".txt"}:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            parts = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
            for idx, part in enumerate(parts):
                chunks.append(
                    {
                        "source": path.name,
                        "chunk": idx,
                        "text": part[:4000],
                    }
                )
        return chunks

    def search(self, query: str, top_k: int = 3) -> list[dict]:
        q = self._tokens(query)
        if not q:
            return []

        scored = []
        for chunk in self._chunks():
            tokens = self._tokens(chunk["text"])
            score = len(q & tokens) / max(len(q), 1)
            if score > 0:
                scored.append((score, chunk))

        scored.sort(key=lambda x: x[0], reverse=True)
        results = []
        for score, chunk in scored[:top_k]:
            item = dict(chunk)
            item["score"] = round(score, 3)
            results.append(item)
        return results
