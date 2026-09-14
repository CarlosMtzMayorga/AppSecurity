-- AlterTable
ALTER TABLE "Visitor" ADD COLUMN "entryCode" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "Visitor_entryCode_key" ON "Visitor"("entryCode");
