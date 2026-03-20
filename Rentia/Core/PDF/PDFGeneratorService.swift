import Foundation
import UIKit

struct PDFGeneratorService {
    static func generatePaymentReceipt(
        payment: Payment,
        tenant: Tenant,
        property: Property,
        owner: UserProfile
    ) -> Data {
        let generatedAt = payment.createdAt
        let pdfMetaData = pdfMetadata(
            author: owner.displayName,
            title: String(localized: "pdf.payment_receipt"),
            generatedAt: generatedAt
        )
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        return renderer.pdfData { context in
            context.beginPage()
            drawPaymentReceiptContent(
                context: context,
                payment: payment,
                tenant: tenant,
                property: property,
                owner: owner,
                generatedAt: generatedAt,
                margin: margin,
                pageWidth: pageWidth
            )
        }
    }

    static func generateLeaseContract(
        lease: Lease,
        tenant: Tenant,
        property: Property,
        owner: UserProfile
    ) -> Data {
        let generatedAt = lease.createdAt
        let pdfMetaData = pdfMetadata(
            author: owner.displayName,
            title: String(localized: "pdf.lease_contract"),
            generatedAt: generatedAt
        )
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        return renderer.pdfData { context in
            context.beginPage()
            drawLeaseContractContent(
                context: context,
                lease: lease,
                tenant: tenant,
                property: property,
                owner: owner,
                generatedAt: generatedAt,
                margin: margin,
                pageWidth: pageWidth
            )
        }
    }

    // MARK: - Payment Receipt Drawing

    private static func drawPaymentReceiptContent(
        context: UIGraphicsPDFRendererContext,
        payment: Payment,
        tenant: Tenant,
        property: Property,
        owner: UserProfile,
        generatedAt: Date,
        margin: CGFloat,
        pageWidth: CGFloat
    ) {
        var yPos: CGFloat = margin
        let contentWidth = pageWidth - (margin * 2)

        yPos = drawHeader(
            title: String(localized: "pdf.payment_receipt"),
            subtitle: String(localized: "pdf.receipt_number") + ": \(payment.id?.prefix(8).uppercased() ?? "—")",
            at: yPos,
            margin: margin,
            pageWidth: pageWidth
        )

        yPos += 20
        yPos = drawSection(
            title: String(localized: "pdf.landlord"),
            lines: [owner.displayName, owner.email],
            at: yPos,
            margin: margin,
            contentWidth: contentWidth
        )

        yPos += 10
        yPos = drawSection(
            title: String(localized: "pdf.tenant"),
            lines: [tenant.fullName, tenant.email, tenant.phone],
            at: yPos,
            margin: margin,
            contentWidth: contentWidth
        )

        yPos += 10
        yPos = drawSection(
            title: String(localized: "pdf.property"),
            lines: [property.name, property.address.formattedAddress],
            at: yPos,
            margin: margin,
            contentWidth: contentWidth
        )

        yPos += 10
        let dateStr = payment.date.formatted(date: .long, time: .omitted)
        let dueDateStr = payment.dueDate.formatted(date: .long, time: .omitted)
        let amountStr = payment.amount.formatted(.currency(code: "EUR"))
        let methodStr = payment.paymentMethod ?? "—"
        yPos = drawDetailRows(
            rows: [
                (String(localized: "pdf.concept"), "\(String(localized: "pdf.rent")) — \(payment.dueDate.monthYear)"),
                (String(localized: "pdf.amount"), amountStr),
                (String(localized: "pdf.date"), dateStr),
                (String(localized: "payments.due_date"), dueDateStr),
                (String(localized: "pdf.payment_method"), methodStr),
            ],
            at: yPos,
            margin: margin,
            contentWidth: contentWidth
        )

        drawFooter(at: 800, margin: margin, generatedAt: generatedAt)
    }

    // MARK: - Lease Contract Drawing

    private static func drawLeaseContractContent(
        context: UIGraphicsPDFRendererContext,
        lease: Lease,
        tenant: Tenant,
        property: Property,
        owner: UserProfile,
        generatedAt: Date,
        margin: CGFloat,
        pageWidth: CGFloat
    ) {
        var yPos: CGFloat = margin
        let contentWidth = pageWidth - (margin * 2)

        yPos = drawHeader(
            title: String(localized: "pdf.lease_contract"),
            subtitle: String(localized: "leases.status.active"),
            at: yPos,
            margin: margin,
            pageWidth: pageWidth
        )

        yPos += 20
        yPos = drawSection(
            title: String(localized: "pdf.landlord"),
            lines: [owner.displayName, owner.email],
            at: yPos,
            margin: margin,
            contentWidth: contentWidth
        )

        yPos += 10
        yPos = drawSection(
            title: String(localized: "pdf.tenant"),
            lines: [tenant.fullName, tenant.email, tenant.phone],
            at: yPos,
            margin: margin,
            contentWidth: contentWidth
        )

        yPos += 10
        yPos = drawSection(
            title: String(localized: "pdf.property"),
            lines: [property.name, property.address.formattedAddress],
            at: yPos,
            margin: margin,
            contentWidth: contentWidth
        )

        yPos += 10
        let startStr = lease.startDate.formatted(date: .long, time: .omitted)
        let endStr = lease.endDate?.formatted(date: .long, time: .omitted) ?? String(localized: "leases.indefinite")
        let rentStr = lease.rentAmount.formatted(.currency(code: "EUR"))
        let depositStr = lease.depositAmount.formatted(.currency(code: "EUR"))
        yPos = drawDetailRows(
            rows: [
                (String(localized: "leases.start_date"), startStr),
                (String(localized: "leases.end_date"), endStr),
                (String(localized: "leases.rent_amount"), rentStr),
                (String(localized: "leases.deposit_amount"), depositStr),
                (String(localized: "leases.billing_day"), "\(lease.billingDay)"),
            ],
            at: yPos,
            margin: margin,
            contentWidth: contentWidth
        )

        drawFooter(at: 800, margin: margin, generatedAt: generatedAt)
    }

    // MARK: - Drawing Helpers

    @discardableResult
    private static func drawHeader(
        title: String,
        subtitle: String,
        at yPos: CGFloat,
        margin: CGFloat,
        pageWidth: CGFloat
    ) -> CGFloat {
        let titleFont = UIFont.boldSystemFont(ofSize: 22)
        let subtitleFont = UIFont.systemFont(ofSize: 13)
        let titleColor = UIColor.label
        let subtitleColor = UIColor.secondaryLabel

        title.draw(
            at: CGPoint(x: margin, y: yPos),
            withAttributes: [.font: titleFont, .foregroundColor: titleColor]
        )
        subtitle.draw(
            at: CGPoint(x: margin, y: yPos + 30),
            withAttributes: [.font: subtitleFont, .foregroundColor: subtitleColor]
        )

        let lineY = yPos + 52
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin, y: lineY))
        linePath.addLine(to: CGPoint(x: pageWidth - margin, y: lineY))
        UIColor.separator.setStroke()
        linePath.stroke()

        return lineY + 12
    }

    @discardableResult
    private static func drawSection(
        title: String,
        lines: [String],
        at yPos: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat
    ) -> CGFloat {
        var currentY = yPos
        let titleFont = UIFont.boldSystemFont(ofSize: 12)
        let bodyFont = UIFont.systemFont(ofSize: 12)

        title.uppercased().draw(
            at: CGPoint(x: margin, y: currentY),
            withAttributes: [.font: titleFont, .foregroundColor: UIColor.secondaryLabel]
        )
        currentY += 18

        for line in lines {
            line.draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: [.font: bodyFont, .foregroundColor: UIColor.label]
            )
            currentY += 16
        }
        return currentY
    }

    @discardableResult
    private static func drawDetailRows(
        rows: [(String, String)],
        at yPos: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat
    ) -> CGFloat {
        var currentY = yPos
        let labelFont = UIFont.systemFont(ofSize: 12)
        let valueFont = UIFont.boldSystemFont(ofSize: 12)
        let rowHeight: CGFloat = 24

        for (label, value) in rows {
            label.draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: [.font: labelFont, .foregroundColor: UIColor.secondaryLabel]
            )
            let valueWidth: CGFloat = 200
            value.draw(
                at: CGPoint(x: margin + contentWidth - valueWidth, y: currentY),
                withAttributes: [.font: valueFont, .foregroundColor: UIColor.label]
            )
            currentY += rowHeight
        }
        return currentY
    }

    private static func drawFooter(at yPos: CGFloat, margin: CGFloat, generatedAt: Date) {
        let font = UIFont.systemFont(ofSize: 10)
        let text = "Rentia — \(generatedAt.formatted(date: .abbreviated, time: .omitted))"
        text.draw(
            at: CGPoint(x: margin, y: yPos),
            withAttributes: [.font: font, .foregroundColor: UIColor.tertiaryLabel]
        )
    }

    private static func pdfMetadata(author: String, title: String, generatedAt: Date) -> [String: Any] {
        [
            "Creator": "Rentia",
            "Author": author,
            "Title": title,
            "CreationDate": generatedAt,
            "ModDate": generatedAt,
        ]
    }
}
