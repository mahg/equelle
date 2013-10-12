/*
  Copyright 2013 SINTEF ICT, Applied Mathematics.
*/

#include "PrintCPUBackendASTVisitor.hpp"
#include "ASTNodes.hpp"
#include "SymbolTable.hpp"
#include <iostream>
#include <cctype>



PrintCPUBackendASTVisitor::PrintCPUBackendASTVisitor()
    : suppressed_(false), vars_with_types_(false), indent_(0)
{
}

PrintCPUBackendASTVisitor::~PrintCPUBackendASTVisitor()
{
}





void PrintCPUBackendASTVisitor::visit(SequenceNode&)
{
    // std::cout << "{SequenceNode::visit()}";
}

void PrintCPUBackendASTVisitor::midVisit(SequenceNode&)
{
    // std::cout << "{SequenceNode::midVisit()}";
}

void PrintCPUBackendASTVisitor::postVisit(SequenceNode&)
{
    // std::cout << "{SequenceNode::postVisit()}";
}

void PrintCPUBackendASTVisitor::visit(NumberNode& node)
{
    std::cout.precision(16);
    std::cout << "double(" << node.number() << ")";
}

void PrintCPUBackendASTVisitor::visit(TypeNode&)
{
    // std::cout << SymbolTable::equelleString(node.type());
}

void PrintCPUBackendASTVisitor::visit(FuncTypeNode&)
{
    // std::cout << node.funcType().equelleString();
}

void PrintCPUBackendASTVisitor::visit(BinaryOpNode&)
{
    std::cout << '(';
}

void PrintCPUBackendASTVisitor::midVisit(BinaryOpNode& node)
{
    char op = ' ';
    switch (node.op()) {
    case Add:
        op = '+';
        break;
    case Subtract:
        op = '-';
        break;
    case Multiply:
        op = '*';
        break;
    case Divide:
        op = '/';
        break;
    default:
        break;
    }
    std::cout << ' ' << op << ' ';
}

void PrintCPUBackendASTVisitor::postVisit(BinaryOpNode&)
{
    std::cout << ')';
}

void PrintCPUBackendASTVisitor::visit(NormNode&)
{
    std::cout << "er.norm(";
}

void PrintCPUBackendASTVisitor::postVisit(NormNode&)
{
    std::cout << ')';
}

void PrintCPUBackendASTVisitor::visit(UnaryNegationNode&)
{
    std::cout << '-';
}

void PrintCPUBackendASTVisitor::postVisit(UnaryNegationNode&)
{
}

void PrintCPUBackendASTVisitor::visit(OnNode&)
{
    std::cout << "er.On(";
}

void PrintCPUBackendASTVisitor::midVisit(OnNode&)
{
    std::cout << ", ";
}

void PrintCPUBackendASTVisitor::postVisit(OnNode&)
{
    std::cout << ')';
}

void PrintCPUBackendASTVisitor::visit(TrinaryIfNode&)
{
    std::cout << "er.trinaryIf(";
}

void PrintCPUBackendASTVisitor::questionMarkVisit(TrinaryIfNode&)
{
    std::cout << ", ";
}

void PrintCPUBackendASTVisitor::colonVisit(TrinaryIfNode&)
{
    std::cout << ", ";
}

void PrintCPUBackendASTVisitor::postVisit(TrinaryIfNode&)
{
    std::cout << ')';
}

void PrintCPUBackendASTVisitor::visit(VarDeclNode&)
{
    suppress();
}

void PrintCPUBackendASTVisitor::postVisit(VarDeclNode&)
{
    unsuppress();
}

void PrintCPUBackendASTVisitor::visit(VarAssignNode& node)
{
    std::cout << "const auto " << node.name() << " = ";
}

void PrintCPUBackendASTVisitor::postVisit(VarAssignNode&)
{
    std::cout << ';';
    endl();
}

void PrintCPUBackendASTVisitor::visit(VarNode& node)
{
    if (vars_with_types_) {
        std::cout << "<Type...>" << node.name();
    } {
        std::cout << node.name();
    }
}

void PrintCPUBackendASTVisitor::visit(FuncRefNode& node)
{
    std::cout << node.name();
}

void PrintCPUBackendASTVisitor::visit(JustAnIdentifierNode&)
{
}

void PrintCPUBackendASTVisitor::visit(FuncArgsDeclNode&)
{
    std::cout << "{FuncArgsDeclNode::visit()}";
}

void PrintCPUBackendASTVisitor::midVisit(FuncArgsDeclNode&)
{
    std::cout << "{FuncArgsDeclNode::midVisit()}";
}

void PrintCPUBackendASTVisitor::postVisit(FuncArgsDeclNode&)
{
    std::cout << "{FuncArgsDeclNode::postVisit()}";
}

void PrintCPUBackendASTVisitor::visit(FuncDeclNode&)
{
    // std::cout << node.name() << " : ";
}

void PrintCPUBackendASTVisitor::postVisit(FuncDeclNode&)
{
    // endl();
}

void PrintCPUBackendASTVisitor::visit(FuncStartNode& node)
{
    std::cout << "auto " << node.name() << " = [&](";
    const FunctionType& ft = SymbolTable::getFunction(node.name()).functionType();
    const size_t n = ft.arguments().size();
    for (int i = 0; i < n; ++i) {
        std::cout << cppTypeString(ft.arguments()[i].type())
                  << ' ' << ft.arguments()[i].name() << std::flush;
        if (i < n - 1) {
            std::cout << ", " << std::flush;
        }
    }
    suppress();
}

void PrintCPUBackendASTVisitor::postVisit(FuncStartNode& node)
{
    unsuppress();
    const FunctionType& ft = SymbolTable::getFunction(node.name()).functionType();
    std::cout << ") -> " << cppTypeString(ft.returnType()) << " {";
    endl();
}

void PrintCPUBackendASTVisitor::visit(FuncAssignNode&)
{
    ++indent_;
}

void PrintCPUBackendASTVisitor::postVisit(FuncAssignNode&)
{
    std::cout << "}";
    endl();
}

void PrintCPUBackendASTVisitor::visit(FuncArgsNode&)
{
}

void PrintCPUBackendASTVisitor::midVisit(FuncArgsNode&)
{
    if (!suppressed_) {
        std::cout << ", ";
    }
}

void PrintCPUBackendASTVisitor::postVisit(FuncArgsNode&)
{
}

void PrintCPUBackendASTVisitor::visit(ReturnStatementNode&)
{
    std::cout << "return ";
}

void PrintCPUBackendASTVisitor::postVisit(ReturnStatementNode&)
{
    std::cout << ';';
    --indent_;
    endl();
}

void PrintCPUBackendASTVisitor::visit(FuncCallNode& node)
{
    const std::string fname = node.name();
    const char first = fname[0];
    std::string cppname = std::isupper(first) ?
        std::string("er.") + char(std::tolower(first)) + fname.substr(1)
        : fname;
    std::cout << cppname << '(';
}

void PrintCPUBackendASTVisitor::postVisit(FuncCallNode&)
{
    std::cout << ')';
}

void PrintCPUBackendASTVisitor::visit(FuncCallStatementNode&)
{
}

void PrintCPUBackendASTVisitor::postVisit(FuncCallStatementNode&)
{
    std::cout << ';';
    endl();
}



void PrintCPUBackendASTVisitor::endl() const
{
    std::cout << '\n' << indent();
}

std::string PrintCPUBackendASTVisitor::indent() const
{
    return std::string(indent_*4, ' ');
}

void PrintCPUBackendASTVisitor::suppress()
{
    suppressed_ = true;
}

void PrintCPUBackendASTVisitor::unsuppress()
{
    suppressed_ = false;
}

std::string PrintCPUBackendASTVisitor::cppTypeString(const EquelleType& et) const
{
    std::string cppstring = et.isCollection() ? "CollOf" : "";
    cppstring += basicTypeString(et.basicType());
    return cppstring;
}
