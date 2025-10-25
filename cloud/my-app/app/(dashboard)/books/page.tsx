import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function BooksPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">单词书管理</h1>
      <Card>
        <CardHeader>
          <CardTitle>概览</CardTitle>
          <CardDescription>在此管理你的单词书（示例占位）</CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-zinc-600 dark:text-zinc-400">
            这里可以添加、编辑、删除单词书。你可以根据需要扩展为表格、表单等。
          </p>
        </CardContent>
      </Card>
    </div>
  );
}


